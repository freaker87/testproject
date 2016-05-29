public class MassApprovalPopulateRecords {
@AuraEnabled
    public static List<ProcessInstanceWorkitem> getPendingRecords(string objectName)
    {
        List<ProcessInstanceWorkitem> piwiList = [SELECT ActorId,Id,IsDeleted,ProcessInstanceId, ProcessInstance.targetobjectid 
                FROM ProcessInstanceWorkitem where actorid =:userinfo.getUserId()];
        List<ProcessInstanceWorkitem> retVal = new List<ProcessInstanceWorkitem>();
        for(ProcessInstanceWorkitem piwi:piwiList){
        	if(String.valueOf(piwi.ProcessInstance.targetobjectid.getSObjectType())==objectName)
            {
                retVal.add(piwi);
            }
        }
        return retVal;
    }
}