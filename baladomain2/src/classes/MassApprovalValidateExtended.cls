public class MassApprovalValidateExtended extends MassApprovalValidate {

    public override boolean canWeProceed(){
        List<string> ss = new List<string>();
        ss.addAll(idsToCheck);
        return false;
    }
}