/*
* Company: Google Inc.
* Date: July 2019
* Author: Google Inc.
* Description: This test class invokes a mock endpoint
* to test the methods in the GCPManageCustomerService class. 
* History: Version 1.0
*/

@isTest
public class GCPManageCustomersServiceTest {
    @testSetup
    static void setup() {
        List<Account> testCustomers = new List<Account>();
        testCustomers.add(new Account(name='Sample Customer Account'));
        insert testCustomers;
    }
    
    static testmethod void testQueueable() {
        
        String action = 'create';
        List<Account> accounts = [select id, name from account where name like 'Sample Customer%'];
        String serialisedAccs = JSON.serialize(accounts);
        GCPManageCustomersService managecustomerstest = new GCPManageCustomersService(serialisedAccs, action);
        
        // startTest/stopTest block to force async processes to run
        Test.setMock(HttpCalloutMock.class, new GCPMockHttpResponseGenerator());
        Test.startTest();
        System.enqueueJob(managecustomerstest);
        Test.stopTest();
        
        // Validate the job ran
        /* AsyncApexJob jobInfo = [SELECT 
                                	Status, 
                                	NumberOfErrors
    							FROM 
                                	AsyncApexJob 
                                WHERE Id = :jobID]; */
        
        
    }
    
     static testmethod void testGCPCallout() {
        String action = 'create';
        List<Account> accounts = [select id, name from account where name like 'Sample Customer%'];
        String serialisedAccs = JSON.serialize(accounts);
        GCPManageCustomersService managecustomerstest = new GCPManageCustomersService(serialisedAccs, action);
        
        // startTest/stopTest block to force async processes to run
        Test.setMock(HttpCalloutMock.class, new GCPMockHttpResponseGenerator());
        Test.startTest();
        	managecustomerstest.updateCustomerMasterInGCP('test', 'http://testendpoint');
        Test.stopTest();
        
     }
    
}