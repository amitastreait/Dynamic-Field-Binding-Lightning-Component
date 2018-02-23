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