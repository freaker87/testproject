public virtual class MassApprovalValidate {
	public final List<string> idsToCheck;
    public MassApprovalValidate(){}
    public MassApprovalValidate(List<string> idsToCheck){
        this.idsToCheck = idsToCheck;
        system.debug('*** passed ids :: '+idsToCheck);
    }
    public virtual boolean canWeProceed(){
        
        return true;
    }
    
}