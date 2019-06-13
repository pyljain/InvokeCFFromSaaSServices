/*
* Company: Google Inc.
* Date: July 2019
* Author: Google Inc.
* Description: This class generates a mock response for the
* HTTP callout made from the test class called GCPManageCustomersServiceTest
* History: Version 1.0
*/
@isTest
global class GCPMockHTTPResponseGenerator implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        
        System.assertEquals('POST', req.getMethod());
        System.assertEquals('application/json', req.getHeader('Content-Type'));
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status":"Done"}');
        res.setStatusCode(200);
        return res;
    }
}