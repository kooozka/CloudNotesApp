// Konfiguracja AWS Amplify dla Amazon Cognito
// UWAGA: Te wartości powinny być docelowo ustawione jako zmienne środowiskowe w Elastic Beanstalk

const awsConfig = {
    // Główna konfiguracja
    Auth: {
        Cognito: {
            userPoolId: process.env.REACT_APP_USER_POOL_ID || 'us-east-1_XXXXXXXXX', // Zaktualizuj na swój prawdziwy User Pool ID
            userPoolClientId: process.env.REACT_APP_USER_POOL_CLIENT_ID || 'XXXXXXXXXXXXXXXXX', // Zaktualizuj na swój prawdziwy App Client ID
            // loginWith: {
            //     oauth: {
            //         domain: process.env.REACT_APP_COGNITO_DOMAIN || 'notes-app-XXXXXXXXX.auth.us-east-1.amazoncognito.com', // Zaktualizuj na swoją domenę
            //         scope: ['email', 'profile', 'openid'],
            //         redirectSignIn: process.env.REACT_APP_REDIRECT_SIGN_IN || 'http://266537-notes-app-frontend.us-east-1.elasticbeanstalk.com/',
            //         redirectSignOut: process.env.REACT_APP_REDIRECT_SIGN_OUT || 'http://266537-notes-app-frontend.us-east-1.elasticbeanstalk.com/',
            //         responseType: 'code'
            //     }
            // }
        }
    },
    // Region
    region: process.env.REACT_APP_AWS_REGION || 'us-east-1'
};

export default awsConfig;