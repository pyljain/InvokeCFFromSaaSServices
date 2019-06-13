/*
* Company: Google Inc.
* Date: July 2019
* Author: Google Inc.
* Description: This class invokes the Google token endpoint secure 
* an ID Token in exchange of a JSON wek token. It then invokes a 
* web callout to a GCP Cloud Function to send newly created 
* customer accounts in Salesforce to GCP so they can be securely stored
* in the system of record customer master.
* History: Version 1.0
*/

public class GCPManageCustomersService implements Queueable, Database.AllowsCallouts {
    
    // Serialised customer accounts
    private String serialisedAccs;
    
    // Action to be performed in GCP, can be 'create' customer account in this example
    private String action;
    
    // Class to deserialise response from the Google token URL and get the ID Token
    class GoogleAuthResponse {
        public String id_token;
    }
    
    class FunctionsRequest {
        public List<Account> customers;
        public String action;
    }
    
    public GCPManageCustomersService(String serialisedRecords, String action) {
        this.serialisedAccs = serialisedRecords;
        this.action = action;
    }
    
    @TestVisible
    private void updateCustomerMasterInGCP(String token, String functionEndpoint) {
        
        List<Account> deserialisedAccounts = (List<Account>)JSON.deserialize(serialisedAccs, List<Account>.class); 
        
        FunctionsRequest requestMessage = new FunctionsRequest();
        requestMessage.customers = deserialisedAccounts;
        requestMessage.action = action;
        
        HTTP http = new HTTP();
        HTTPRequest req = new HTTPRequest();
        req.setHeader('Content-Type','application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setEndpoint(functionEndpoint);
        //req.setEndpoint('https://us-central1-deliveroo-1540203586751.cloudfunctions.net/securefunction');
        req.setMethod('POST');   
        req.setBody(JSON.serialize(requestMessage));   
        HTTPResponse response=new HttpResponse();
        System.debug('CALLOUT EXECUTION STARTING');
        response = http.send(req);
        
        if (response.getStatusCode() != 200) {
            System.debug('Error occured ' +response.getStatus() + ' ' +response.getStatusCode());
        } else {
            System.debug(response.getBody());
        }
    }
    
    public void execute(QueueableContext context) {
        
        List<GCP_Key__mdt> gcp_sa_keys = new List<GCP_Key__mdt>();
        gcp_sa_keys = [SELECT
                       client_email__c,
                       audience__c,
                       token_endpoint__c
                       FROM GCP_Key__mdt];
        
        Auth.JWT jwt = new Auth.JWT();
        jwt.setAud(gcp_sa_keys[0].token_endpoint__c);
        // jwt.setAud('https://www.googleapis.com/oauth2/v4/token'); 
        jwt.setIss(gcp_sa_keys[0].client_email__c);
        
        System.debug('VALUES' + gcp_sa_keys[0]);
        
        //Additional claims to set scope
        Map<String, Object> claims = new Map<String, Object>();
        claims.put('target_audience', gcp_sa_keys[0].audience__c);
        jwt.setAdditionalClaims(claims);
        
        System.debug('toJSONString()' + jwt.toJSONString());        
        
        //Create the object that signs the JWT bearer token
        Auth.JWS jws = new Auth.JWS(jwt, 'google_cloud');
        
        //Get the resulting JWS in case debugging is required
        String token = jws.getCompactSerialization();
        System.debug('JWT Token to be sent ' + token);
        
        //Set the token endpoint that the JWT bearer token is posted to
        String tokenEndpoint = gcp_sa_keys[0].token_endpoint__c;
        
        //POST the JWT bearer token
        if (!Test.isRunningTest()) {
            Auth.JWTBearerTokenExchange bearer = new Auth.JWTBearerTokenExchange(tokenEndpoint, jws); 
            
            // Response to the ID Token request in exchange of the Salesforce generated JWT
            System.HttpResponse response = bearer.getHTTPResponse();
            //System.debug('TOKEN RETURNED BY GOOGLE' + response.getBody());
            
            GoogleAuthResponse authResponse = 
                (GoogleAuthResponse) JSON.deserialize(response.getBody(), GoogleAuthResponse.class);
            
            if (authResponse.id_token != '') {
                this.updateCustomerMasterInGCP(authResponse.id_token, gcp_sa_keys[0].audience__c);
            }
            
        }
    }
}