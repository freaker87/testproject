public class MassApprovalDashboardController {
     @AuraEnabled
    public static List<Wrapper> getAllAccessibleObjects()
    {
        List<string> allAPINames = new List<string>();
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe(); 
        List<string> apiNames = new List<string>();
        List<String> allObjectLabels = new List<string>();
        
        map<String,string> allKeyPrefixs = new map<string,string>();
        
        Map<string,string> labelName = new Map<string,string>();
        for(string objectApi: globalDescribe.keyset()){         
            apiNames.add(objectApi);
        }
        Schema.DescribeSobjectResult[] results  = Schema.describeSObjects(apiNames);
        for(Schema.DescribeSobjectResult describeResult  : results){                
            if(describeResult.isAccessible()) {
                allAPINames.add(String.valueOf(describeResult.getName()));
                labelName.put(String.valueOf(describeResult.getName()),String.valueOf(describeResult.getLabel()));
                if(String.valueOf(describeResult.getKeyPrefix())!=null)
                allKeyPrefixs.put(String.valueOf(describeResult.getKeyPrefix()),String.valueOf(describeResult.getName()));
           }
        }
        
        //check if the objects posses an approval process
        List<ProcessDefinition> processDefinitionList = [select id,TableEnumOrId From ProcessDefinition WHERE TableEnumOrId IN:labelName.keySet()];
        if(processDefinitionList!=null && processDefinitionList.size()>0)
        {
            for(ProcessDefinition pd:processDefinitionList)
                allObjectLabels.add(labelName.get(pd.TableEnumOrId));
        }
        List<Wrapper> retWrapper = countOfRecords(allAPINames,allKeyPrefixs);
        if(retWrapper!=null && retWrapper.size()<1)
        {
            retWrapper = new List<Wrapper>();
            for(string s:allObjectLabels)
            {
                retWrapper.add(new Wrapper(s,0));
            }
        }
        else if(retWrapper.size()!=allObjectLabels.size())
        {
            set<string> names = new set<string>();
            names.addAll(allObjectLabels);
            for(string ele:names){
                for(Wrapper w:retWrapper)
                {
                    if(ele==w.objectName)
                    {}
                    else
                    {
                        retWrapper.add(new Wrapper(ele,0));
                    }
                    break;
                }
            }
           
        }
        system.debug('**** main method ::: '+retWrapper.size()+' ** '+retWrapper+' '+allObjectLabels);
        return retWrapper;//JSON.serialize(retWrapper);
    }
    
    public static List<Wrapper> countOfRecords(List<string> allApis,map<string,string> allKeyPrefixs)
    {
        
        Map<string,Integer> retMap = new Map<string,Integer>();
        List<Wrapper> wrapList = new List<Wrapper>();
        List<ProcessInstanceWorkitem> piwiList = [SELECT ActorId,Id,IsDeleted,ProcessInstanceId, ProcessInstance.targetobjectid 
                FROM ProcessInstanceWorkitem where actorid =:userinfo.getUserId()];
        system.debug('########## '+allKeyPrefixs.keySet());
        for(ProcessInstanceWorkitem piwi:piwiList)
        {
            for(string s:allKeyPrefixs.keySet()){
                if(String.valueOf(piwi.ProcessInstance.targetobjectid).startswith(s))
                {
                    if(retMap.get(String.valueOf(piwi.ProcessInstance.targetobjectid.getSObjectType()))!=null)
                    {
                        Integer count = retMap.get(String.valueOf(piwi.ProcessInstance.targetobjectid.getSObjectType()));
                     retMap.put(String.valueOf(piwi.ProcessInstance.targetobjectid.getSObjectType()),count+1);
                    }
                    else
                    {
                     retMap.put(String.valueOf(piwi.ProcessInstance.targetobjectid.getSObjectType()),1);
                    }
                }
    }
        }
        
      
                for(string objectName:retMap.keySet())
                  wrapList.add(new Wrapper(objectName,retMap.get(objectName)));
       return wrapList;
    }
    
    public class Wrapper
    {
        @AuraEnabled
        public string objectName{get;set;}
        @AuraEnabled
        public Integer count{get;set;}
        
        public Wrapper(string objectName,Integer count)
        {
            this.objectName = objectName;
            this.count = count;
        }
    }
    
    @AuraEnabled
    public static DisplayWrapper getPendingRecords(string objectName)
    {
        List<ProcessInstanceWorkitem> piwiList = [SELECT ActorId,Id,IsDeleted,ProcessInstanceId, ProcessInstance.targetobjectid 
                FROM ProcessInstanceWorkitem where actorid =:userinfo.getUserId()];
        List<Id> retValList = new List<Id>();
        Map<Id,Id> processInstanceWrkItemIdMap = new Map<Id,Id>();
        for(ProcessInstanceWorkitem piwi:piwiList){
            if(String.valueOf(piwi.ProcessInstance.targetobjectid.getSObjectType())==objectName)
            {
                retValList.add(piwi.ProcessInstance.targetobjectid);
                processInstanceWrkItemIdMap.put(piwi.ProcessInstance.targetobjectid,piwi.id);
            }
        }
        DisplayWrapper dw = new DisplayWrapper(objectName,retValList,processInstanceWrkItemIdMap);
        return dw;
    }
    
    public class DisplayWrapper
    {
        @AuraEnabled
        public string name{Get;set;}
        @AuraEnabled
        public  List<string> fs{get;set;}
        @AuraEnabled
        public List<sObject> showRecords{Get;set;}
        @AuraEnabled
        public Map<string,List<string>> showRecordValueMap{Get;set;}
        @AuraEnabled
        public Map<string,string> labelFieldMap{get;set;}
        @AuraEnabled
        public List<string> labelFieldList{get;set;}
        @AuraEnabled
        public Map<Id,Id> piwiObjMap{get;set;}
        
        public DisplayWrapper(string name,List<Id> listItem,Map<Id,Id> processWrItds){
            
            piwiObjMap = new Map<Id,Id>();
            piwiObjMap.putAll(processWrItds);
            Schema.SObjectType convertType = Schema.getGlobalDescribe().get(name);
            Schema.DescribeSObjectResult DescribeSObjectResultObj = convertType.getDescribe();
            String fieldSetName = FieldSetMapping__c.getInstance(name).fieldSetName__c;
            List<Schema.FieldSetMember> fsList = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName).getFields();
            fs = new List<string>();
            labelFieldMap = new Map<string,string>();
            labelFieldList = new List<string>();
            string query ='SELECT id';
            for(Schema.FieldSetMember fm:fsList)
            {
                
                query = query + +','+fm.getFieldPath();
                fs.add(fm.getLabel());
                labelFieldMap.put(fm.getLabel(),fm.getFieldPath());
                labelFieldList.add(fm.getFieldPath());
            }
            query = query+' FROM '+name+' WHERE id IN:listItem';
            system.debug('#### query '+query);
            showRecords = Database.query(query);
            showRecordValueMap = new Map<string,List<string>>();
            for(sObject s:showRecords){
                
                for(string label:labelFieldMap.values())
                {
                    system.debug(s+'%%% '+label+' &&& '+s.get(label)+' $$$ ');
                    if(showRecordValueMap.get(string.valueOf(s.get('id')))!=null)
                    {
                        List<string> tempList = showRecordValueMap.get(string.valueOf(s.get('id')));
                        tempList.add(string.valueOf(s.get(label)!=null?s.get(label):'NA'));
                      showRecordValueMap.put(String.valueOf(s.get('id')),tempList);
                    }
                    else{
                        if(s.get(label)!=null)
                          showRecordValueMap.put(string.valueOf(s.get('id')),new List<string>{string.valueOf(s.get(label))});
                        else
                          showRecordValueMap.put(string.valueOf(s.get('id')),new List<string>{'NA'});
                    }
                }
            }
        }
    }
    
    @AuraEnabled
    public static string massApproveRecords(List<string> toApproveIds,string actionType){
        
        //check if we can proceed 
        MassApprovalValidate mav = new MassApprovalValidate(toApproveIds);
        if(mav.canWeProceed()){
             List<Id> jsonRecordIds = new List<Id>();
       		 for(string s:toApproveIds){
            	jsonRecordIds.add(Id.valueOf(s));
        	}
        	List<Approval.ProcessWorkitemRequest> reqList = new List<Approval.ProcessWorkitemRequest>();
        	string action = actionType.contains('approv')?'Approve':'Reject';
        	string comment = action=='Approve'?'Approving':'Rejecting';
        	for(id piwi:jsonRecordIds){
        		Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
				req2.setComments('Request Processed. - '+comment);
				req2.setAction(action); //This is the action that is approve in your case, you can set it to Reject also
				req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
				req2.setWorkitemId(piwi);
				reqList.add(req2);
        	}
        // Submit the request for approval
        	try{  
    			List<Approval.ProcessResult> result2 =  Approval.process(reqList);
        		return 'success';    
        	}catch(Exception e){
            return 'failed '+e.getMessage();
        	}
        }//we can proceed
      else{
      	return 'Validations failed';
      }  
    }
}