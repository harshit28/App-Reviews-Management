({
	doInit : function(component, event, helper) {
		console.log('in doinit');
        var action = component.get("c.getReviews");
        action.setParams({ "packageName" : component.get("v.pckgName") });
        action.setCallback(this, function(response) {
            console.log(response.getReturnValue());
            var rec = response.getReturnValue();
            if(rec!=null)
            {
                var res = rec;
                var lstResult = [];
                //var counter = 1;
                for(var i = 0;i<res.length;i++)
                {
                    var caseExist;
                    if(res[i].Case__c == '' || res[i].Case__c == undefined)
                        caseExist = false;
                    else
                        caseExist = true;
                    console.log(caseExist);
                    
                    var output = {};
                    output.Id = i;
                    output.AuthorName = res[i].Author_Name__c;
                    output.Title = res[i].Title__c;
                    output.Rating = res[i].Rating__c;
                    output.Content = res[i].Content__c;
                    output.ReviewId = res[i].Review_ID__c;
                    output.DevComment = res[i].Developer_Comment__c;
                    output.isSubmitted = $A.util.isUndefinedOrNull(res[i].Developer_Comment__c) ? false : true;
                    output.AppName = res[i].App__c;
                    output.ImgURL = res[i].App_Image__c;
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
    fetchReviews : function(component, event, helper)
    {
        var action = component.get("c.insertReviews");
        action.setParams({ "packageName" : component.get("v.pckgName") });
        action.setCallback(this, function(response){
            console.log(response.getReturnValue());
            var rec = response.getReturnValue();
            if(rec != null && rec.length>0)
            {
                var res = rec;
                var lstResult = [];
                //var counter = 1;
                for(var i = 0;i<res.length;i++){
                    var caseExist;
                    if(res[i].Case__c == '' || res[i].Case__c == undefined)
                        caseExist = false;
                    else
                        caseExist = true;
                    console.log(caseExist);
                    
                    var output = {};
                    output.Id = i;
                    output.AuthorName = res[i].Author_Name__c;
                    output.Title = res[i].Title__c;
                    output.Rating = res[i].Rating__c;
                    output.Content = res[i].Content__c;
                    output.ReviewId = res[i].Review_ID__c;
                    output.DevComment = res[i].Developer_Comment__c;
                    output.isSubmitted = $A.util.isUndefinedOrNull(res[i].Developer_Comment__c) ? false : true;
                    output.AppName = res[i].App__c;
                    output.ImgURL = res[i].App_Image__c;
                    output.CaseId = caseExist;
                    lstResult.push(output);
                }
                console.log(lstResult);
                component.set("v.result",lstResult);
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "message": "Latest App Reviews has been Retrieved!",
                    "mode": "dismissible",
                    "type": "success"
                });
                toastEvent.fire();
                
                
                /*var res = rec;
                var lstReviews = (JSON.parse(res))['reviews'];
                console.log(lstReviews);
                var lstResult = [];
                for(var i = 0;i<lstReviews.length;i++)
                {
                    var output = {};
                    var authorName = lstReviews[i]['authorName'];
                    var userComment = lstReviews[i]['comments'][0]['userComment']['text'].trim();
                    var rating = lstReviews[i]['comments'][0]['userComment']['starRating'];
                    
                    if(authorName == '')
                    {
                        console.log('no name');
                        authorName = 'anonymous';
                    }
                    if(lstReviews[i]['comments'][1] != undefined)
                    {
                        console.log('###dev comment');
                        console.log(lstReviews[i]['comments'][1]['developerComment']['text'].trim());
                        output.DevComment = lstReviews[i]['comments'][1]['developerComment']['text'].trim();
                    }
                    output.Id = i;
                    output.AuthorName = authorName;
                    output.Rating = rating;
                    output.Content = userComment;
                    lstResult.push(output);
                    
                    console.log(lstReviews[i]['authorName']);
                    console.log(lstReviews[i]['comments'][0]['userComment']['text'].trim());
                    console.log(lstReviews[i]['comments'][0]['userComment']['starRating']);
                    console.log(lstReviews[i]['comments'][1]);
                    
                }
                console.log(lstResult);
                component.set("v.result",lstResult);*/
            }
            else if(rec == null)
            {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "message": "Please Authorize to Retrieve Reviews!",
                    "mode": "dismissible",
                    "type": "error"
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
            document.getElementById(index).disabled = true;
            
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
    replyToReview : function(component, event, helper)
    {
        console.log('in reply');
        console.log(event.getSource().get("v.value"));
        var index = event.getSource().get("v.value");
        var arr = [];
        arr = component.get("v.result");
        console.log(arr.isSubmitted);
        arr[index].isSubmitted = true;
        component.set("v.result",arr);
        
        var action = component.get("c.replyReview");
        action.setParams({ "packageName" : component.get("v.pckgName"), "appReview" : JSON.stringify(component.get("v.result")[index]) });
        action.setCallback(this, function(response) {
            console.log(response.getReturnValue());
            var flag = response.getReturnValue();
            if(flag == true)
            {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "message": "Reply Posted Successfully!",
                    "mode": "dismissible",
                    "type": "success"
                });
                toastEvent.fire();
            }
            else
            {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "message": "Please Authorize to Post a Reply!",
                    "mode": "dismissible",
                    "type": "error"
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    }
})