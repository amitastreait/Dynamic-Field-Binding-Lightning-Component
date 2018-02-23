/*
 * @Author : Amit Singh
 * @Date : 22nd Feb 2018
 * @Description : Class is responsible for getting the dynamic data and sending back to 
 * 				: Lightning Component
 */ 
public class DynamicBindingDemoController {
    /*
     * @Author : Amit Singh
     * @Date : 22nd Feb 2018
     * @Description : Method to return all available Object to Lightning Component
     * @Return Type : List<String>
     * @Params : none
     */
	@AuraEnabled
    public static List<String> listAllObject(){
        List<String> objectList = new List<String>();
        For(Schema.sObjectType sobj: schema.getGlobalDescribe().values()){
            if(sobj.getDescribe().isQueryable())
            	objectList.add(sobj.getDescribe().getName()+'####'+sobj.getDescribe().getLabel());
        }
        return objectList;
    }
    /*
     * @Author : Amit Singh
     * @Date : 22nd Feb 2018
     * @Description : Method to return the dynamic data based on the Selected Object Lightning Component
     * @Return Type : DynamicBindingWrapper wrapper class
     * @Params : Strig ObjectName
     */
    @AuraEnabled
    public static DynamicBindingWrapper listAllFields(String objectName){
        DynamicBindingWrapper dynamicData = new DynamicBindingWrapper();
        List<fieldDataWrapper> wrapperList =  new List<fieldDataWrapper>();
        // Create Dynamic Query Start ..
        String theQuery = 'SELECT ';
        SObjectType sObjectName = Schema.getGlobalDescribe().get(objectName);
        Map<String,Schema.SObjectField> mfields = sObjectName.getDescribe().fields.getMap();
        For(Schema.SObjectField field : mfields.values()){
            If(field.getDescribe().isAccessible() && !field.getDescribe().getName().EndsWith('Id')
               && field.getDescribe().getName()!='CreatedDate' && field.getDescribe().getName()!='LastModifiedDate'
               && field.getDescribe().getName()!='LastReferencedDate' && field.getDescribe().getName()!='LastReferencedDate'
               && field.getDescribe().getName()!='LastActivityDate' && field.getDescribe().getName()!='LastViewedDate'
               && field.getDescribe().getName()!='IsDeleted'){
               fieldDataWrapper wrapper = new fieldDataWrapper();
               theQuery += field.getDescribe().getName() + ',' ;
                wrapper.label = field.getDescribe().getLabel();
                wrapper.apiName = field.getDescribe().getName();
                wrapperList.add(wrapper);
           } 
        }
        // Trim last comma
        theQuery = theQuery.subString(0, theQuery.length() - 1);
        // Finalize query string
        theQuery += ' FROM '+objectName+' LIMIT 15';
        // Query End ..
        System.debug('#### theQuery = '+theQuery);
        List<sObject> objectData = Database.Query(theQuery);
        if(objectData!=null && objectData.size()>0)
        	dynamicData.sObjectData = objectData;
        else
            dynamicData.sObjectData = new List<sObject>{};
        dynamicData.fieldList = wrapperList;
        System.debug('#### dynamicData '+dynamicData);
        return dynamicData;
    }
    /* Class to store the dynamic data 
     * and list of related fields
     */ 
    public class DynamicBindingWrapper{
        @AuraEnabled
        public List<sObject> sObjectData    { get; set; }
        @AuraEnabled
        public List<fieldDataWrapper> fieldList { get; set; }
    }
    /*
     * Class to store the field information
     */ 
    public class fieldDataWrapper{
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String apiName { get; set; }
    }
}