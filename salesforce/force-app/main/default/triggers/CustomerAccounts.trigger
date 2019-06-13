trigger CustomerAccounts on Account (after insert) {
    
    
    if (Trigger.isInsert) {
      List<Account> accs = trigger.new;
      String serialisedAccs = JSON.serialize(accs);
      //GetGCPIDToken getIDToken = new GetGCPIDToken(serialisedAccs, 'create');
      GCPManageCustomersService gcpService = new GCPManageCustomersService(serialisedAccs, 'create');
      ID jobID = System.enqueueJob(gcpService);
      //APIController.insertCustomerRecordsinGCP(accs);
    }
}