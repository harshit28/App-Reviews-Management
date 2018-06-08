({
    doInit : function(component, event, helper) 
    {
        console.log('in doinit');
        var action = component.get("c.getReviews");
        action.setParams({appId : component.get("v.appID")});
        action.setCallback(this, function(response) {
            console.log(response.getReturnValue());
            var rec = response.getReturnValue();
            if(rec!=null)
            {
                var res = rec;
                var lstResult = [];
                console.log("res.length::"+res.length);
                //var counter = 1;
                for(var i = 0;i<res.length;i++){
                    //console.log('########');
                    //console.log(res[i].Case__c);
                    var caseExist;
                    if(res[i].Case__c == '' || res[i].Case__c == undefined)
                        caseExist = false;
                    else
                        caseExist = true;
                    
                    if($A.util.isUndefinedOrNull(res[i].Image_Id__c))
                    {
                        //console.log('####true');
                    }
                    else
                    {
                        console.log('false######');
                        component.set("v.imageContentId",res[i].Image_Id__c);
                    }
                    var output = {};
                    output.Id = i;
                    output.AuthorName = res[i].Author_Name__c;
                    output.Title = res[i].Title__c;
                    output.Rating = res[i].Rating__c;
                    output.Content = res[i].Content__c;
                    output.AppName = res[i].App__c;
                    output.ImgURL = res[i].App_Image__c;
                    output.ReviewId = res[i].Review_ID__c;
                    output.CaseId = caseExist;
                    lstResult.push(output);
                }
                console.log(lstResult);
                component.set("v.result",lstResult);
            }
            //console.log('return after save: '+rec); 
        });
        $A.enqueueAction(action); 
    },
    createCase : function(component, event, helper)
    {
        console.log('in create case');
        //console.log(event.getSource().get("v.name"));
        //var cmpTarget = component.find('0');
        
        //console.log(cmpTarget);
        //$A.util.addClass(cmpTarget, 'slds-hide');
        var entry = event.currentTarget;
        var index = entry.dataset.record;
        console.log(index);
        console.log(component.get("v.result")[index]);
        var arr = [];
        arr = component.get("v.result")[index];
        
        var action = component.get("c.createCaseApex");
        action.setParams({"obj" : JSON.stringify(arr)});
        action.setCallback(this, function(response){
            console.log(response.getReturnValue());
            //document.getElementById(index).disabled = true;
            
            var result = component.get("v.result")
            result[index].CaseId = true;
            
            component.set("v.result",result);
            
            
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "message": "Case Created Successfully!",
                "mode": "dismissible",
                "type": "success"
            });
            toastEvent.fire();
            
            /*var cmpTarget = component.find(index);
            console.log(index);
        	$A.util.addClass(cmpTarget, 'slds-hide');*/
        });
        $A.enqueueAction(action);
    },
    insertReview : function(component,event,helper){
        //var arr = [];
        //arr = component.get("v.result");
        console.log('appid:'+component.get("v.appID"));
        var action = component.get("c.insertReviews");
        action.setParams({ "appId" : component.get("v.appID"), "countryCode" : component.get("v.countryCode") });
        action.setCallback(this, function(response){
            console.log(response.getReturnValue());
            //document.getElementById(index).disabled = true;
            
            var rec = response.getReturnValue();
            if(rec!=null)
            {
                var res = rec;
                var lstResult = [];
                //var counter = 1;
                for(var i = 0;i<res.length;i++){
                    //console.log('########');
                    //console.log(res[i].Case__c);
                    var caseExist;
                    if(res[i].Case__c == '' || res[i].Case__c == undefined)
                        caseExist = false;
                    else
                        caseExist = true;
                    
                    if($A.util.isUndefinedOrNull(res[i].Image_Id__c))
                    {
                        //console.log('####true');
                    }
                    else
                    {
                        console.log('false######');
                        component.set("v.imageContentId",res[i].Image_Id__c);
                    }
                    
                    var output = {};
                    output.Id = i;
                    output.AuthorName = res[i].Author_Name__c;
                    output.Title = res[i].Title__c;
                    output.Rating = res[i].Rating__c;
                    output.Content = res[i].Content__c;
                    output.AppName = res[i].App__c;
                    output.ImgURL = res[i].App_Image__c;
                    output.ReviewId = res[i].Review_ID__c;
                    output.CaseId = caseExist;
                    lstResult.push(output);
                }
                console.log(lstResult);
                component.set("v.result",lstResult);
            
            /*var rec = response.getReturnValue();
            if(rec != null)
            {
                var res = rec;
                //console.log((JSON.parse(res))['feed'].entry[1]);
                var lstEntry = (JSON.parse(res))['feed'].entry;
                console.log('###################');
                console.log(lstEntry[0]['im:image'][1]['label']);
                console.log(component.get("v.result"));
                var lstResult = [];
                //var counter = 1;
                for(var i = 1;i<lstEntry.length;i++){
                    //console.log(lstEntry[i]['author']['name']['label']);
                    //console.log(lstEntry[i]['title']);
                    var output = {};
                    output.Id = i-1;
                    output.AuthorName = lstEntry[i]['author']['name']['label'];
                    output.Title = lstEntry[i]['title']['label'];
                    output.Rating = lstEntry[i]['im:rating']['label'];
                    output.Content = lstEntry[i]['content']['label'];
                    output.AppName = lstEntry[0]['im:name']['label'];
                    output.ImgURL = lstEntry[0]['im:image'][1]['label'];
                    output.ReviewId = lstEntry[i]['id']['label'];
                    output.CaseId = false;
                    lstResult.push(output);
                }
                console.log(lstResult);
                component.set("v.result",lstResult);*/
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "message": "Latest App Reviews has been Retrieved!",
                    "mode": "dismissible",
                    "type": "success"
                });
                toastEvent.fire();
            }
            else
            {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "message": "No Latest App Reviews Available.",
                    "mode": "dismissible",
                    "type": "error"
                });
                toastEvent.fire();
            }
            /*var cmpTarget = component.find(index);
            console.log(index);
        	$A.util.addClass(cmpTarget, 'slds-hide');*/
        });
        $A.enqueueAction(action);
    },
    showSpinner : function(component,event,helper)
    {
        var spinner = component.find("spinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.util.addClass(spinner, "slds-show");
    },
    hideSpinner : function(component,event,helper)
    {
        var spinner = component.find("spinner");
        $A.util.removeClass(spinner, "slds-show");
        $A.util.addClass(spinner, "slds-hide");
        
    }
})