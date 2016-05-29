public class MassApprovalDashboardControllerAng {
     @RemoteAction
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
        if(retWrapper==null)
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
        
        public string objectName{get;set;}
        
        public Integer count{get;set;}
        
        public Wrapper(string objectName,Integer count)
        {
            this.objectName = objectName;
            this.count = count;
        }
    }
    
    @RemoteAction
    public static DisplayWrapper getPendingRecords(string objectName)
    {
        List<ProcessInstanceWorkitem> piwiList = [SELECT ActorId,Id,IsDeleted,ProcessInstanceId, ProcessInstance.targetobjectid 
                FROM ProcessInstanceWorkitem where actorid =:userinfo.getUserId()];
        List<Id> retValList = new List<Id>();
        
        for(ProcessInstanceWorkitem piwi:piwiList){
            if(String.valueOf(piwi.ProcessInstance.targetobjectid.getSObjectType())==objectName)
            {
                retValList.add(piwi.ProcessInstance.targetobjectid);
            }
        }
        DisplayWrapper dw = new DisplayWrapper(objectName,retValList);
        return dw;
    }
    
    public class DisplayWrapper
    {
        public List<RecordWrapper> rwList{get;set;}
        public string name{Get;set;}        
        public  List<string> fs{get;set;}        
        public List<sObject> showRecords{Get;set;}        
        public Map<string,List<string>> showRecordValueMap{Get;set;}        
        public Map<string,string> labelFieldMap{get;set;}
        public List<string> labelFieldList{get;set;}
        
        
        public DisplayWrapper(string name,List<Id> listItem){
            
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
            labelFieldList.add('Id');
            query = query+' FROM '+name+' WHERE id IN:listItem';
            system.debug('#### query '+query);
            showRecords = Database.query(query);
            rwList = new List<RecordWrapper>();
            //populate the required records as JSON
            for(sObject s:showRecords)
            {
              RecordWrapper rw = new RecordWrapper();
              Map<string,string> newMap = new Map<string,string>();
              for(string str:labelFieldMap.values()){              
                newMap.put(str,String.valueOf(s.get(str))!=null?string.valueOf(s.get(str)):'NA');                
              }
              newMap.put('Id',String.valueOf(s.get('Id')));
              rw.nameValuePair = newMap;
              rwList.add(rw);
            }
        }
    }
 
 //Wrapper Wrapper
 public class RecordWrapper{
  public Map<string,string> nameValuePair{get;set;}
  }   
}