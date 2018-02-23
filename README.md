# Dynamic-Field-Binding-Lightning-Component

Most of you must be aware of that In Lightning, Component Dynamic component is not available. Recently I was working on one of my projects and implemented the Dynamic binding using the lightning component so I am going to share how I implemented the same so that it may help others.

As we all know that we can use the Dynamic Binding in the VisualForce page but in Lightning Component it is not Possible. 

In this example, We will show the list of Objects into the Component and when user will select any object it will dynamically show the TOP 15 records into a table.

Output will look like below
![Output](https://github.com/amitastreait/Dynamic-Field-Binding-Lightning-Component/blob/master/OutPut.png)


Step1 - Create Apex Class
DynamicBindingDemoController.class
```
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
```

Step2 - Create the Lightning Component

DynamicBindingDemo.cmp
```
<aura:component implements="force:appHostable,flexipage:availableForAllPageTypes,flexipage:availableForRecordHome,force:hasRecordId,force:lightningQuickAction,force:hasSObjectName" 
                controller='DynamicBindingDemoController'
                access="global" >
    <!-- call the doInit method to load the list of All the Available Objects into the Org -->
    <aura:handler name='init' value='{!this}' action='{!c.doInit}' />
    <aura:attribute name='objectList' type='List' />
    <aura:attribute name="isSending" type="boolean" />
    <c:spinner /> 
    <div class="slds-m-around_small">
        <div class="slds-page-header">
            <div class="slds-media">
                <div class="slds-media__body">
                    <h1 class="slds-page-header__title slds-truncate slds-align-middle" title="Dynamic Binding in Ligtning Component">
                        Dynamic Field Binding in Ligtning Component</h1>
                    <p class="slds-text-body_small slds-line-height_reset">
                        By SFDC Panther • 24/02/2018</p>
                </div>
            </div><br/>
        </div><br/>
        <div class="slds-grid slds-wrap">
            <div class="slds-size_1-of-2">
                <div class="slds-box_x-small">
                    <!-- show the list of All the Object -->
                    <lightning:select name="selectObject" label="Select an Object" 
                                      onchange="{!c.doHandleChange}" aura:id='selectObject'>
                        <option value="" text="- None -" />
                        <aura:iteration items='{!v.objectList}' var='obj'>
                            <option value="{!obj.key}" text="{!obj.value}" />
                        </aura:iteration>
                    </lightning:select>
                </div>
            </div>
            <br/>
            <ui:scrollerWrapper class="scrollerSize">
                <div class="slds-size_2-of-2">
                    <div id='sfdctable' aura:id='sfdcDiv'>
                        <!-- devision that will show the dynamic content -->
                    </div>
                </div>
            </ui:scrollerWrapper>
        </div>
    </div>
</aura:component>
```

See the comments into the component.

Step3: - Click on Controller from the right and paste the below code for Controller Javascript
DynamicBindingDemoController.js
```

({
    doInit : function(component, event, helper) {
        helper.onInit(component, event, helper);
    },
    doHandleChange : function(component, event, helper) {
        helper.onHandleChange(component, event, helper);
    },
})

```
Step4: - Click on Helper from the right and paste the below code for Helper Javascript

DynamicBindingDemoHelper.js
```

({
    onInit : function(component, event, helper) {
        /* Call the Apex class method to fetch the List of all object */
        var action = component.get('c.listAllObject');
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS' && component.isValid()){
                /* set the value to the attribute of the component */
                var responseValue = response.getReturnValue();
                var lstOptions = [];
                for(var i=0; i < responseValue.length; i++){
                    lstOptions.push({
                        value : responseValue[i].split('####')[1],
                        key : responseValue[i].split('####')[0]
                    });
                }
                lstOptions.sort();
                component.set('v.objectList', lstOptions);
                
            }else{
                var errors = response.getError();
                $A.log(errors);
                if(errors || errors[0].message){
                    console(errors[0].message);
                }
            }
        });
        $A.enqueueAction(action);
    },
    onHandleChange : function(component, event, helper){
        /* Call this method whenever user will select the Obejct
         * and show the Dynamic Content */
        var selObject = component.find('selectObject').get('v.value');
        var action = component.get('c.listAllFields');
        if(selObject!=null && selObject!='' && selObject!=undefined){
            action.setParams({
                "objectName" : selObject  
            });
            action.setCallback(this, function(response){
                var state = response.getState();
                if( state === 'SUCCESS' && component.isValid()){
                    //component.find("dynamicBody").set("v.body",[]);
                    component.find('sfdcDiv').set("v.body",[]);
                    var responseValue = response.getReturnValue();
                    var objectValue   = responseValue.sObjectData;
                    var fieldList     = responseValue.fieldList;
                    
                    /* Create Dynamic Table */
                    var sObjectDataTableHeader = [];
                    // Create table Header
                    for (var i=0; i <  fieldList.length; i++) {
                        sObjectDataTableHeader.push(fieldList[i].label);
                    }
                    console.log(sObjectDataTableHeader);
                    //Get the count of columns.
                    var columnCount = sObjectDataTableHeader.length;
                    //Create a HTML Table element.
                    var table = document.createElement("TABLE");
                    //table.border = "1";
                    //Add the header row.
                    var row = table.insertRow(-1);
                    for (var i = 0; i < columnCount; i++) {
                        var headerCell = document.createElement("TH");
                        headerCell.innerHTML = sObjectDataTableHeader[i];
                        headerCell.className='hearderClass';
                        row.appendChild(headerCell);
                    }
                    var dvTable = document.getElementById("sfdctable");
                    dvTable.innerHTML = "";
                    dvTable.appendChild(table);
                    /* Create Dynamic Table End */
                    
                    if(objectValue.length){
                        for(var j=0; j < objectValue.length; j++){
                            // Dynamic table Row
                            row = table.insertRow(-1);
                            // Dynamic Table Row End
                            for (var i=0; i <  fieldList.length; i++) {
                                // Dynamic table Row
                                var cell = row.insertCell(-1);
                                cell.innerHTML = objectValue[j][fieldList[i].apiName];
                                component.set('v.isSending' , false);
                                
                            }
                        }
                    }else{
                        
                    }
                }else{
                    var errors = response.getError();
                    $A.log('Error Details '+errors);
                    if( errors || errors[0].message){
                        console.log('Error Details '+errors[0].message);
                    }
                }
            });
            $A.enqueueAction(action);
        }else{
            component.set('v.isSending' , false);
        }
    },
})

```
See the comments.

Step5: - Create Lightning Application
DynamicBindingDemoApplication.app
```
<aura:application access="Global" extends="force:slds" >
<c:DynamicBindingDemo />
</aura:application>
```
Click on Preview to see the output of the component.

Happy learning :)

Sharing is caring :) ;)

Resource:- 

[OPFOCOUS Blog](https://opfocus.com/dynamic-field-binding-in-salesforce-lightning-experience/)
