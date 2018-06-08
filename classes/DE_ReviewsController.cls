public class DE_ReviewsController 
{
    @AuraEnabled
    public static List<AppStoreReviews__c> getReviews(String appId)
    {
        List<AppStoreReviews__c> appList = [Select Name,Author_Name__c,Title__c,Content__c,Rating__c,Image_Id__c,Page__c,App_Image__c,App__c,Source__c,App_ID__c,Review_ID__c,Case__c
                                            from AppStoreReviews__c 
                                            where Page__c='1'and App_ID__c=:appId
                                            order by Name desc limit 50 ];
        if(appList.size()>0)
            return appList;
        else
            return null;
    }
    @AuraEnabled
    public static List<AppStoreReviews__c> insertReviews(String appId, String countryCode)
    {
        String result= '';
        //List<AppStoreReviews__c> apList = new List<AppStoreReviews__c>();
        List<AppStoreReviews__c> reverseAppList = new List<AppStoreReviews__c>();
        List<AppStoreReviews__c> appRevList = [Select Id,Name,Review_ID__c from AppStoreReviews__c where App_ID__c=:appId]; 
        Map<String,Id> appMap = new Map<String,Id>();
        for(AppStoreReviews__c app:appRevList)
        {
            if(app.Review_ID__c != null || app.Review_ID__c!= '')
            {
                appMap.put(app.Review_ID__c, app.Id);
            }
        }
        Set<String> revIdSet = new Set<String>();
        Boolean flag = false;
        Blob image;
        String imageURL;
        for(integer k=1; k<=10; k++)
        {
            List<AppStoreReviews__c> apList = new List<AppStoreReviews__c>();
            HttpRequest req = new HttpRequest();
            Http http = new Http();
            string url = 'https://itunes.apple.com/rss/customerreviews/page='+k+'/id='+appId+'/sortby=mostrecent/json?cc='+countryCode+'';
            
            req.setMethod('GET');            
            req.setEndPoint(url);            
            System.debug('URL ' + url);
            
            String jsonResults = '';            
            
            HTTPResponse resp = http.send(req);            
            jsonResults = resp.getBody();
            String st = resp.getStatus();
            
            system.debug('st:'+st);
            
            if(k == 1)
                result = jsonResults;
            
            system.debug('####next#####');
            
            Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(jsonResults);
            
            Map<String,Object> feed = (Map<String,Object>)jsonMap.get('feed');
            
            List<Object> entryList = (List<Object>)feed.get('entry');
            system.debug('entryList:'+entryList);
            if(entryList != null && entryList.size()>0)
            {
                Map<String,Object> entry = (Map<String,Object>)entryList[0];
                
                Map<String,Object> appLabel = (Map<String,Object>)entry.get('im:name');
                String appName = (String)appLabel.get('label');
                
                List<Object> imgList = (List<Object>)entry.get('im:image');
                Map<String,Object> images = (Map<String,Object>)imgList[1];
                String imgURL = (String)images.get('label');
                //system.debug('imgURL:'+imgURL);
               	
                for(integer i=1; i<entryList.size(); i++)
                {
                    if(k==1 && i==1)
                    {
                        system.debug('###in image callout');
                        Http h = new Http();
                        HttpRequest reqImg = new HttpRequest();
                        imageURL = imgURL;
                        //Replace any spaces with %20
                        imageURL = imageURL.replace(' ', '%20');
                        reqImg.setEndpoint(imageURL);
                        reqImg.setMethod('GET');
                        //If you want to get a PDF file the Content Type would be 'application/pdf'
                        reqImg.setHeader('Content-Type', 'image/jpeg');
                        reqImg.setCompressed(true);
                        
                        HttpResponse res = null;
                        res = h.send(reqImg);
                        //These next three lines can show you the actual response for dealing with error situations
                        String responseValue = '';
                        responseValue = res.getBody();
                        //system.debug('Response Body for File: ' + responseValue);
                        //This is the line that does the magic.  We can get the blob of our file.  This getBodyAsBlob method was added in the Spring 2012 release and version 24 of the API.
                        image = res.getBodyAsBlob();
                    }
                    Map<String,Object> entries = (Map<String,Object>)entryList[i];
                    
                    Map<String,Object> author = (Map<String,Object>)entries.get('author');
                    Map<String,Object> authorNameLabel = (Map<String,Object>)author.get('name');
                    String authorName = (String)authorNameLabel.get('label');
                    
                    Map<String,Object> ratingLabel = (Map<String,Object>)entries.get('im:rating');
                    String rating = (String)ratingLabel.get('label');
                    
                    Map<String,Object> revIdLabel = (Map<String,Object>)entries.get('id');
                    String revId = (String)revIdLabel.get('label');
                    
                    Map<String,Object> titleLabel = (Map<String,Object>)entries.get('title');
                    String title = (String)titleLabel.get('label');
                    
                    Map<String,Object> contentLabel = (Map<String,Object>)entries.get('content');
                    String content = (String)contentLabel.get('label');
                    
                    if(appMap.containsKey(revId))
                    {
                        system.debug('#####in if contains review id#####');
                        flag = true;
                        break;
                    }
                    AppStoreReviews__c ap = new AppStoreReviews__c();
                    ap.Review_ID__c = revId;
                    ap.Author_Name__c = authorName;
                    ap.Rating__c = rating;
                    ap.Content__c = content;
                    ap.Title__c = title;
                    ap.App__c = appName;
                    ap.Page__c = String.valueOf(k);
                    ap.App_Image__c = imgURL;
                    ap.Source__c = 'Apple App Store';
                    ap.App_ID__c = appId;
                    ap.Country_Code__c = countryCode;
                    apList.add(ap);
                    
                    if(ap.Rating__c == '1' || ap.Rating__c == '2')
                    {
                        //system.debug('if rating 1 or 2');
                        revIdSet.add(ap.Review_ID__c);
                    }
                }
                system.debug('#######aplist size######'+apList.size());
                system.debug('#######reverseAppList size######'+reverseAppList.size());
                //system.debug('apList:'+apList.size());
                // reversing apList to insert reviews in desc order
                if(apList.size()>0 && apList != null)
                {
                    for(integer j=apList.size()-1; j>=0; j--)
                    {
                        reverseAppList.add(apList[j]);
                    }
                }
            }
            if(flag == true)
            {
                system.debug('#####in if flag true#####');
                break;
            }
            //return jsonResults;
        }
        //system.debug('#######insert######'+apList.size());
        system.debug('#######insert reverseAppList######'+reverseAppList.size());
        if(reverseAppList.size()>0)
        {
            ContentVersion cv = new ContentVersion();
            cv.VersionData = image;  //This is our blob
            cv.title = 'AppleAppImage';
            cv.Description = 'AppleAppImage';
            //cv.FirstPublishLocationId = '058E00000000RIg';  //This is the library
            cv.TagCsv = 'Tag1';
            cv.PathOnClient = imageURL;
            cv.ReasonForChange = ''; // If we update an image then we may have to set this
            //cv.ContentDocumentID = ''; //If we are inserting a revision to a document then we need this.  May have to query for it first
            //When testing this remember that it takes a few seconds for a document to show up in the library
            insert cv;
            system.debug('cv:'+cv);
            
            reverseAppList[0].Image_Id__c = cv.Id;
            
            //insert reverseAppList;
            
            system.debug('revIdSet:'+revIdSet.size());
            
            List<Case> cList = new List<Case>();
            Map<String,Case> cMap = new Map<String,Case>();
            
            //system.debug('##:'+revIdSet.contains(reverseAppList[0].Review_ID__c));
            for(integer i=0;i<reverseAppList.size();i++)
            {
                if(revIdSet.contains(reverseAppList[i].Review_ID__c))
                {
                    //system.debug('in for1');
                    Case c = new Case();
                    c.Subject = reverseAppList[i].Title__c;
                    c.Description = reverseAppList[i].Content__c;
                    //c.Origin = 'Apple App Store';
                    
                    cList.add(c);
                    cMap.put(reverseAppList[i].Review_ID__c,c);
                }
            }
            system.debug('clist:'+cList.size());
            insert cList;
            system.debug('clist:'+cList.size());
            
            for(integer i=0;i<reverseAppList.size();i++)
            {
                if(revIdSet.contains(reverseAppList[i].Review_ID__c))
                {
                    Case c = cMap.get(reverseAppList[i].Review_ID__c);
                    //system.debug('case:'+c);
                    reverseAppList[i].Case__c = c.Id;
                }
            }
            insert reverseAppList;
            
            List<AppStoreReviews__c> appList = [Select Name,Author_Name__c,Title__c,Content__c,Image_Id__c,Rating__c,Page__c,App_Image__c,App__c,Source__c,App_ID__c,Review_ID__c,Case__c
                                                from AppStoreReviews__c 
                                                where Page__c='1'and App_ID__c=:appId
                                                order by Name desc limit 50 ];
            return appList;
        }
        else
            return null;
    }
    @AuraEnabled
    public static void createCaseApex(String obj)
    {
        system.debug('obj:'+obj);
        WrapperObject wo = (WrapperObject)JSON.deserialize(obj, DE_ReviewsController.WrapperObject.class);
        system.debug('wo:'+wo);
        
        AppStoreReviews__c appRev = [Select Id,Author_Name__c,Review_ID__c,Case__c from AppStoreReviews__c where Review_ID__c=:wo.ReviewId];
        
        Case c = new Case();
        c.Subject = wo.Title;
        c.Description = wo.Content;
        //c.Origin = 'Apple App Store';
        insert c;
        system.debug('c:'+c);
        
        appRev.Case__c = c.Id;
        update appRev;
        
    }
    
    public class WrapperObject
    {
        @AuraEnabled
        public String ReviewId{get;set;}
        @AuraEnabled
        public String AuthorName{get;set;}
        @AuraEnabled
        public String Title{get;set;}
        @AuraEnabled
        public String Rating{get;set;}
        @AuraEnabled
        public String Content{get;set;}
        
        public WrapperObject(String ReviewId, String AuthorName, String Title, String Rating, String Content)
        {
            this.ReviewId = ReviewId;
            this.AuthorName = AuthorName;
            this.Title = Title;
            this.Rating = Rating;
            this.Content = Content;
        }
    }
}