package com.example.notesapp.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.auth.credentials.EnvironmentVariableCredentialsProvider;
import software.amazon.awssdk.auth.credentials.InstanceProfileCredentialsProvider;
import software.amazon.awssdk.core.exception.SdkClientException;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;

import java.io.IOException;
import java.util.UUID;

@Service
public class S3Service {
    private static final Logger logger = LoggerFactory.getLogger(S3Service.class);

    @Value("${aws.s3.bucket-name}")
    private String bucketName;
    
    private final S3Client s3Client;
    
    public S3Service() {
        try {
            // Zmiana regionu na US-EAST-1 zgodnie z konfiguracją Terraform
            this.s3Client = S3Client.builder()
                    .region(Region.US_EAST_1)
                    // Próbujemy użyć InstanceProfileCredentialsProvider (dla EC2/Elastic Beanstalk)
                    // a jeśli zawiedzie, to EnvironmentVariableCredentialsProvider
                    .credentialsProvider(InstanceProfileCredentialsProvider.create())
                    .build();
            logger.info("S3 client initialized with region US_EAST_1");
        } catch (Exception e) {
            logger.error("Failed to initialize S3 client", e);
            throw new RuntimeException("Could not initialize S3 client: " + e.getMessage(), e);
        }
    }
    
    public String uploadFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            logger.error("Attempted to upload null or empty file");
            throw new IllegalArgumentException("File cannot be null or empty");
        }
        
        try {
            String fileName = generateFileName(file);
            logger.info("Uploading file {} to S3 bucket {}", fileName, bucketName);
            
            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(fileName)
                    .contentType(file.getContentType())
                    .build();
            
            s3Client.putObject(putObjectRequest, RequestBody.fromBytes(file.getBytes()));
            logger.info("Successfully uploaded file {} to S3", fileName);
            
            return String.format("https://%s.s3.amazonaws.com/%s", bucketName, fileName);
        } catch (IOException e) {
            logger.error("Failed to read file content", e);
            throw new RuntimeException("Failed to read file content: " + e.getMessage(), e);
        } catch (S3Exception s3e) {
            logger.error("S3 service error during file upload", s3e);
            throw new RuntimeException("S3 error: " + s3e.getMessage(), s3e);
        } catch (SdkClientException sdke) {
            logger.error("AWS SDK client error during file upload", sdke);
            throw new RuntimeException("AWS client error: " + sdke.getMessage(), sdke);
        } catch (Exception e) {
            logger.error("Unexpected error during file upload", e);
            throw new RuntimeException("Upload failed: " + e.getMessage(), e);
        }
    }
    
    private String generateFileName(MultipartFile file) {
        return UUID.randomUUID().toString() + "_" + file.getOriginalFilename().replaceAll("[^a-zA-Z0-9.-]", "_");
    }
}