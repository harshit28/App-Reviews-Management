public class DE_PlayStoreReviewsCtrl 
{
    @AuraEnabled
    public static List<AppStoreReviews__c> getReviews(String packageName)
    {
        List<AppStoreReviews__c> appList = [Select Name,Author_Name__c,Title__c,Content__c,Case__c,Rating__c,App__c,Source__c,Review_ID__c,Developer_Comment__c,App_Package_Name__c,App_Image__c
                                            from AppStoreReviews__c 
                                            where Source__c='Google Play Store' and App_Package_Name__c=:packageName
                                            order by Name desc limit 50 ];
        if(appList.size()>0)
            return appList;
        else
            return null;
    }
    @AuraEnabled
    public static List<AppStoreReviews__c> insertReviews(String packageName)
    {
        List<AppStoreReviews__c> apList = new List<AppStoreReviews__c>();
        List<AppStoreReviews__c> appRevList = [Select Id,Name,Review_ID__c from AppStoreReviews__c where Source__c='Google Play Store' and App_Package_Name__c=:packageName]; 
        Map<String,Id> appMap = new Map<String,Id>();
        Set<String> revIdSet = new Set<String>();
        
        for(AppStoreReviews__c app:appRevList)
        {
            appMap.put(app.Review_ID__c, app.Id);
        }
        Boolean flag = false;
        Boolean nextPageFlag = false;
        String nextPageToken = '';
        
        Google_API_Tokens__c accTok = Google_API_Tokens__c.getValues('Access Token');
        String accToken;
        
        if(accTok != null){
            accToken = accTok.Token_Value__c;
        }
        system.debug('accToken:'+accToken);
        
        //String accToken = 'ya29.Gl9wBfqyzsZq-pSRx62NxcRvz7B981f4lVGJ6ocvsvG6e8TnXHUJqZrZqEfTPIwnzsPF-DFLL6hCWLe6m1WQS2oYhdbIpf-iWD3xjGBu56C9NUyHtb1tk7YUHyxF78ehzg';
        
        
        HttpRequest req = new HttpRequest();
        Http http = new Http();
        
        string url = 'https://www.googleapis.com/androidpublisher/v2/applications/'+packageName+'/reviews?access_token='+accToken+'&maxResults=100';
        
        req.setMethod('GET');            
        req.setEndPoint(url);            
        System.debug('URL ' + url);
        
        String jsonResults = '';            
        
        HTTPResponse resp = http.send(req);            
        jsonResults = resp.getBody();
        String st = resp.getStatus();
        
        system.debug('st:'+st);
        
        if(st == 'Unauthorized')
            return null;
        
        system.debug('jsonResults:'+jsonResults);
        
        if(jsonResults.length()<5)
            return new List<AppStoreReviews__c>();
        
        Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(jsonResults);
        
        Map<String,Object> nextPage = (Map<String, Object>)jsonMap.get('tokenPagination');
        //system.debug('nextPage:'+nextPage);
        if(nextPage != null)
        {
            system.debug('###not null##');
            nextPageFlag = true;
            nextPageToken = (String)nextPage.get('nextPageToken');
            
        }
        List<Object> reviewsList = (List<Object>)jsonMap.get('reviews');
        system.debug('reviewsList:'+reviewsList.size());
        
        while(nextPageFlag == true)
        {
            HttpRequest reqNextPage = new HttpRequest();
            Http httpNextPage = new Http();
            
            String urlNextPage = 'https://www.googleapis.com/androidpublisher/v2/applications/'+packageName+'/reviews?access_token='+accToken+'&token='+nextPageToken+'&maxResults=100';
            
            reqNextPage.setMethod('GET');            
            reqNextPage.setEndPoint(urlNextPage);            
            System.debug('urlNextPage ' + urlNextPage);
            
            String jsonResultsNextPage = '';            
            
            HTTPResponse respNextPage = http.send(reqNextPage);            
            jsonResultsNextPage = respNextPage.getBody();
            String status = respNextPage.getStatus();
            
            system.debug('status:'+status);
            
            Map<String, Object> jsonMapNextPage = (Map<String, Object>)JSON.deserializeUntyped(jsonResultsNextPage);
            
            Map<String,Object> nextPage2 = (Map<String, Object>)jsonMapNextPage.get('tokenPagination');
            //system.debug('nextPage:'+nextPage);
            if(nextPage2 != null)
            {
                system.debug('###not null##');
                nextPageFlag = true;
                nextPageToken = (String)nextPage2.get('nextPageToken');
            }
            else
                nextPageFlag = false;
            
            List<Object> reviewsListNextPage = (List<Object>)jsonMapNextPage.get('reviews');
            for(Object obj:reviewsListNextPage)
            {
                reviewsList.add(obj);
            }
        }
        
        String title;
        String imgURL;
        String accessToken = accToken;
        String editId;
        String editIdFlag = '';
        Google_API_Tokens__c editIdTok = Google_API_Tokens__c.getValues('Edit Id');
        
        if(editIdTok != null){
            editId = editIdTok.Token_Value__c;
        }
        
        system.debug('######'+editIdTok);
        system.debug('######'+editId);
        
        if(editIdTok == null)
        {
            // inserting a new edit id
            String endPoint = 'https://www.googleapis.com/androidpublisher/v2/applications/'+packageName+'/edits';
            String jsonstr = '{"id": "12345aaa6", "expiryTimeSeconds":10000000}';
            
            Http h2 = new Http();
            HttpRequest req1 = new HttpRequest();
            req1.setHeader('Authorization','Bearer ' + accessToken);
            req1.setHeader('Content-Type','application/json');
            req1.setBody(jsonstr);
            req1.setMethod('POST');
            req1.setEndpoint(endPoint);
            HttpResponse res1 = h2.send(req1);
            system.debug('response : '+res1.getbody());
            system.debug('res:'+res1.getStatus());
            String response = res1.getbody();
            
            if(res1.getStatus() != 'Unauthorized')
            {
                Map<String, Object> respMap = (Map<String, Object>)JSON.deserializeUntyped(response);
                String eId = (String)respMap.get('id');
                system.debug('eId:'+eId);
                
                editIdTok = new Google_API_Tokens__c();
                editIdTok.Name = 'Edit Id';
                editIdTok.Token_Value__c = eId+' '+packageName;
                //insert editIdTok;
                editIdFlag = 'insert';
                editId = eId;
                
                //getting app info from the inserted edit id
                HttpRequest reqAppInfo = new HttpRequest();
                Http httpAppInfo = new Http();
                
                String urlGetAppInfo = 'https://www.googleapis.com/androidpublisher/v2/applications/'+packageName+'/edits/'+editId+'/listings';
                reqAppInfo.setHeader('Authorization','Bearer ' + accessToken);
                reqAppInfo.setMethod('GET');            
                reqAppInfo.setEndPoint(urlGetAppInfo);            
                System.debug('urlGetAppInfo ' + urlGetAppInfo);
                
                String jsonAppInfo = '';            
                
                HTTPResponse respAppInfo = httpAppInfo.send(reqAppInfo);            
                jsonAppInfo = respAppInfo.getBody();
                String stAppInfo = respAppInfo.getStatus();
                
                system.debug('st:'+stAppInfo);
                system.debug('jsonAppInfo:'+jsonAppInfo);
                if(stAppInfo != 'Unauthorized')
                {
                    Map<String, Object> listingMap = (Map<String, Object>)JSON.deserializeUntyped(jsonAppInfo);
                    List<Object> listingList = (List<Object>)listingMap.get('listings');
                    for(integer i=0;i<listingList.size();i++)
                    {
                        Map<String,Object> listing = (Map<String,Object>)listingList[i];
                        title = (String)listing.get('title');
                    }
                    //getting image response from edit id
                    HttpRequest req2 = new HttpRequest();
                    Http http2 = new Http();
                    
                    String url2 = 'https://www.googleapis.com/androidpublisher/v2/applications/'+packageName+'/edits/'+editId+'/listings/en-US/icon';
                    req2.setHeader('Authorization','Bearer ' + accessToken);
                    req2.setMethod('GET');            
                    req2.setEndPoint(url2);            
                    System.debug('URL2 ' + url2);
                    
                    String jsonResults2 = '';            
                    
                    HTTPResponse resp2 = http2.send(req2);            
                    jsonResults2 = resp2.getBody();
                    String st2 = resp2.getStatus();
                    
                    system.debug('st2:'+st2);
                    system.debug('jsonResults2:'+jsonResults2);
                    
                    if(st2 != 'Unauthorized')
                    {
                        Map<String, Object> imagesMap = (Map<String, Object>)JSON.deserializeUntyped(jsonResults2);
                        List<Object> imagesList = (List<Object>)imagesMap.get('images');
                        
                        Map<String,Object> image = (Map<String,Object>)imagesList[0];
                        imgURL = (String)image.get('url');
                    }
                }
            }
        }
        else if(editId != null)
        {
            String[] arr = editId.split(' ');
            String eId = arr[0];
            String packgName = arr[1];
            editId = eId;
            // if app name is same as inserted edit app name
            if(packgName.equals(packageName))
            {
                //if true get the title and image with same edit id
                //getting app info from the inserted edit id
                HttpRequest reqAppInfo = new HttpRequest();
                Http httpAppInfo = new Http();
                
                String urlAppInfo = 'https://www.googleapis.com/androidpublisher/v2/applications/'+packageName+'/edits/'+editId+'/listings';
                reqAppInfo.setHeader('Authorization','Bearer ' + accessToken);
                reqAppInfo.setMethod('GET');            
                reqAppInfo.setEndPoint(urlAppInfo);            
                System.debug('urlAppInfo ' + urlAppInfo);
                
                String jsonAppInfo = '';            
                
                HTTPResponse respAppInfo = httpAppInfo.send(reqAppInfo);            
                jsonAppInfo = respAppInfo.getBody();
                String stAppInfo = respAppInfo.getStatus();
                
                system.debug('stAppInfo:'+stAppInfo);
                system.debug('jsonAppInfo:'+jsonAppInfo);
                
                if(jsonAppInfo.contains('error')==true)
                {
                    //if error
                    //if edit has expired
                    system.debug('######in else eidt expired');
                    
                    String endPoint = 'https://www.googleapis.com/androidpublisher/v2/applications/'+packageName+'/edits';
                    String jsonstr = '{"id": "12345aaa6", "expiryTimeSeconds":10000000}';
                    
                    Http h2 = new Http();
                    HttpRequest req1 = new HttpRequest();
                    req1.setHeader('Authorization','Bearer ' + accessToken);
                    req1.setHeader('Content-Type','application/json');
                    req1.setBody(jsonstr);
                    req1.setMethod('POST');
                    req1.setEndpoint(endPoint);
                    HttpResponse res1 = h2.send(req1);
                    system.debug('response : '+res1.getbody());
                    system.debug('res:'+res1.getStatus());
                    String response = res1.getbody();
                    
                    if(res1.getStatus() != 'Unauthorized')
                    {
                        Map<String, Object> respMap = (Map<String, Object>)JSON.deserializeUntyped(response);
                        String edId = (String)respMap.get('id');
                        system.debug('edId:'+edId);
                        
                        editIdTok.Token_Value__c = edId+' '+packageName;
                        editIdFlag = 'update';
                        //update editIdTok;
                        editId = edId;
                        
                        //getting app info from the inserted edit id
                        HttpRequest reqAppInfoEdit = new HttpRequest();
                        Http httpAppInfoEdit = new Http();
                        
                        String urlAppInfoEdit = 'https://www.googleapis.com/androidpublisher/v2/applications/'+packageName+'/edits/'+editId+'/listings';
                        reqAppInfoEdit.setHeader('Authorization','Bearer ' + accessToken);
                        reqAppInfoEdit.setMethod('GET');            
                        reqAppInfoEdit.setEndPoint(urlAppInfoEdit);            
                        System.debug('urlAppInfoEdit ' + urlAppInfoEdit);
                        
                        String jsonAppInfoEdit = '';            
                        
                        HTTPResponse respAppInfoEdit = httpAppInfoEdit.send(reqAppInfoEdit);            
                        jsonAppInfoEdit = respAppInfoEdit.getBody();
                        String stAppInfoEdit = respAppInfoEdit.getStatus();
                        
                        system.debug('stAppInfoEdit:'+stAppInfoEdit);
                        system.debug('jsonAppInfoEdit:'+jsonAppInfoEdit);
                        if(stAppInfoEdit != 'Unauthorized')
                        {
                            Map<String, Object> listingMap = (Map<String, Object>)JSON.deserializeUntyped(jsonAppInfoEdit);
                            List<Object> listingList = (List<Object>)listingMap.get('listings');
                            for(integer i=0;i<listingList.size();i++)
                            {
                                Map<String,Object> listing = (Map<String,Object>)listingList[i];
                                title = (String)listing.get('title');
                            }
                            //getting image response from edit id
                            HttpRequest req2 = new HttpRequest();
                            Http http2 = new Http();
                            
                            String url2 = 'https://www.googleapis.com/androidpublisher/v2/applications/'+packageName+'/edits/'+editId+'/listings/en-US/icon';
                            req2.setHeader('Authorization','Bearer ' + accessToken);
                            req2.setMethod('GET');            
                            req2.setEndPoint(url2);            
                            System.debug('URL2 ' + url2);
                            
                            String jsonResults2 = '';            
                            
                            HTTPResponse resp2 = http2.send(req2);            
                            jsonResults2 = resp2.getBody();
                            String st2 = resp2.getStatus();
                            
                            system.debug('st2:'+st2);
                            system.debug('jsonResults2:'+jsonResults2);
                            
                            if(st2 != 'Unauthorized')
                            {
                                Map<String, Object> imagesMap = (Map<String, Object>)JSON.deserializeUntyped(jsonResults2);
                                List<Object> imagesList = (List<Object>)imagesMap.get('images');
                                
                                Map<String,Object> image = (Map<String,Object>)imagesList[0];
                                imgURL = (String)image.get('url');
                            }
                        }
                    }
                    
                }
                else
                {
                    system.debug('####in else');  
                    Map<String, Object> listingMap = (Map<String, Object>)JSON.deserializeUntyped(jsonAppInfo);
                    List<Object> listingList = (List<Object>)listingMap.get('listings');
                    system.debug('listingList:'+listingList);
                    if(listingList != null)
                    {
                        for(integer i=0;i<listingList.size();i++)
                        {
                            Map<String,Object> listing = (Map<String,Object>)listingList[i];
                            title = (String)listing.get('title');
                        }
                        //getting image response from edit id
                        HttpRequest req2 = new HttpRequest();
                        Http http2 = new Http();
                        
                        String url2 = 'https://www.googleapis.com/androidpublisher/v2/applications/'+packageName+'/edits/'+editId+'/listings/en-US/icon';
                        req2.setHeader('Authorization','Bearer ' + accessToken);
                        req2.setMethod('GET');            
                        req2.setEndPoint(url2);            
                        System.debug('URL2 ' + url2);
                        
                        String jsonResults2 = '';            
                        
                        HTTPResponse resp2 = http2.send(req2);            
                        jsonResults2 = resp2.getBody();
                        String st2 = resp2.getStatus();
                        
                        system.debug('st2:'+st2);
                        system.debug('jsonResults2:'+jsonResults2);
                        
                        if(st2 != 'Unauthorized')
                        {
                            Map<String, Object> imagesMap = (Map<String, Object>)JSON.deserializeUntyped(jsonResults2);
                            List<Object> imagesList = (List<Object>)imagesMap.get('images');
                            system.debug('imagesList:'+imagesList);
                            if(imagesList != null)
                            {
                                Map<String,Object> image = (Map<String,Object>)imagesList[0];
                                imgURL = (String)image.get('url');
                            }
                        }
                    }
                }
            }
            else
            {
                // if inserted edit app name is different than the user app name
                // create and update new edit id and package app name
                // inserting a new edit id
                String endPoint = 'https://www.googleapis.com/androidpublisher/v2/applications/'+packageName+'/edits';
                String jsonstr = '{"id": "12345aaa6", "expiryTimeSeconds":10000000}';
                
                Http h2 = new Http();
                HttpRequest req1 = new HttpRequest();
                req1.setHeader('Authorization','Bearer ' + accessToken);
                req1.setHeader('Content-Type','application/json');
                req1.setBody(jsonstr);
                req1.setMethod('POST');
                req1.setEndpoint(endPoint);
                HttpResponse res1 = h2.send(req1);
                system.debug('response : '+res1.getbody());
                system.debug('res:'+res1.getStatus());
                String response = res1.getbody();
                
                if(res1.getStatus() != 'Unauthorized')
                {
                    Map<String, Object> respMap = (Map<String, Object>)JSON.deserializeUntyped(response);
                    String edId = (String)respMap.get('id');
                    system.debug('edId:'+edId);
                    
                    editIdTok.Token_Value__c = edId+' '+packageName;
                    editIdFlag = 'update';
                    //update editIdTok;
                    editId = edId;
                    
                    //getting app info from the inserted edit id
                    HttpRequest reqAppInfo = new HttpRequest();
                    Http httpAppInfo = new Http();
                    
                    String urlAppInfo = 'https://www.googleapis.com/androidpublisher/v2/applications/'+packageName+'/edits/'+editId+'/listings';
                    reqAppInfo.setHeader('Authorization','Bearer ' + accessToken);
                    reqAppInfo.setMethod('GET');            
                    reqAppInfo.setEndPoint(urlAppInfo);            
                    System.debug('urlAppInfo ' + urlAppInfo);
                    
                    String jsonAppInfo = '';            
                    
                    HTTPResponse respAppInfo = httpAppInfo.send(reqAppInfo);            
                    jsonAppInfo = respAppInfo.getBody();
                    String stAppInfo = respAppInfo.getStatus();
                    
                    system.debug('stAppInfo:'+stAppInfo);
                    system.debug('jsonAppInfo:'+jsonAppInfo);
                    if(stAppInfo != 'Unauthorized')
                    {
                        Map<String, Object> listingMap = (Map<String, Object>)JSON.deserializeUntyped(jsonAppInfo);
                        List<Object> listingList = (List<Object>)listingMap.get('listings');
                        for(integer i=0;i<listingList.size();i++)
                        {
                            Map<String,Object> listing = (Map<String,Object>)listingList[i];
                            title = (String)listing.get('title');
                        }
                        //getting image response from edit id
                        HttpRequest req2 = new HttpRequest();
                        Http http2 = new Http();
                        
                        String url2 = 'https://www.googleapis.com/androidpublisher/v2/applications/'+packageName+'/edits/'+editId+'/listings/en-US/icon';
                        req2.setHeader('Authorization','Bearer ' + accessToken);
                        req2.setMethod('GET');            
                        req2.setEndPoint(url2);            
                        System.debug('URL2 ' + url2);
                        
                        String jsonResults2 = '';            
                        
                        HTTPResponse resp2 = http2.send(req2);            
                        jsonResults2 = resp2.getBody();
                        String st2 = resp2.getStatus();
                        
                        system.debug('st2:'+st2);
                        system.debug('jsonResults2:'+jsonResults2);
                        
                        if(st2 != 'Unauthorized')
                        {
                            Map<String, Object> imagesMap = (Map<String, Object>)JSON.deserializeUntyped(jsonResults2);
                            List<Object> imagesList = (List<Object>)imagesMap.get('images');
                            
                            Map<String,Object> image = (Map<String,Object>)imagesList[0];
                            imgURL = (String)image.get('url');
                        }
                    }
                }
            }
        }
        
        
        
        if(reviewsList != null && reviewsList.size()>0)
        {
            for(integer i=0; i<reviewsList.size(); i++)
            {
                system.debug('@@@@@in for'+i);
                Map<String,Object> reviews = (Map<String,Object>)reviewsList[i];
                
                String reviewId = (String)reviews.get('reviewId');
                system.debug('reviewId:'+reviewId);
                
                if(appMap.containsKey(reviewId))
                {
                    system.debug('#####in if contains review id#####');
                    flag = true;
                    break;
                }
                
                String authorName = (String)reviews.get('authorName');
                system.debug('authorName:'+authorName);
                
                if(authorName == '')
                    authorName = 'anonymous';
                
                List<Object> commentsList = (List<Object>)reviews.get('comments');
                system.debug('commentsList:'+commentsList.size());
                
                if(commentsList.size()>0)
                {
                    AppStoreReviews__c ap = new AppStoreReviews__c();
                    ap.Review_ID__c = reviewId;
                    ap.Author_Name__c = authorName;
                    ap.Source__c = 'Google Play Store';
                    ap.App_Package_Name__c = packageName;
                    ap.App__c = title;
                    ap.App_Image__c = imgURL;
                    
                    //ap.Page__c = String.valueOf(k);
                    
                    
                    for(integer j=0; j<commentsList.size(); j++)
                    {
                        Map<String,Object> comments = (Map<String,Object>)commentsList[j];
                        if(j==0) //user comments only
                        {
                            Map<String,Object> userComment = (Map<String,Object>)comments.get('userComment');
                            system.debug('userComment:'+userComment);
                            
                            String userText = (String)userComment.get('text');
                            system.debug('userText:'+userText);
                            
                            String[] arr = userText.split('\t');
                            system.debug('arr:'+arr[1]);
                            
                            Decimal rating = (Decimal)userComment.get('starRating');
                            system.debug('rating:'+rating);
                            
                            ap.Rating__c = String.valueOf(rating);
                            ap.Content__c = arr[1];
                            ap.Title__c = arr[0];
                            //apList.add(ap);
                            
                            if(ap.Rating__c == '1' || ap.Rating__c == '2')
                            {
                                system.debug('if rating 1 or 2');
                                revIdSet.add(ap.Review_ID__c);
                            }
                        }
                        else // developer comments if any
                        {
                            Map<String,Object> developerComment = (Map<String,Object>)comments.get('developerComment');
                            system.debug('developerComment:'+developerComment);
                            
                            String developerText = (String)developerComment.get('text');
                            system.debug('developerText:'+developerText);
                            ap.Developer_Comment__c = developerText;
                        }
                    }
                    apList.add(ap);
                }
            }
            system.debug('aplist:'+apList);
            system.debug('apList:'+apList.size());
            List<AppStoreReviews__c> reverseAppList = new List<AppStoreReviews__c>();
            if(apList.size()>0 && apList != null)
            {
                for(integer j=apList.size()-1; j>=0; j--)
                {
                    reverseAppList.add(apList[j]);
                }
            }
            if(editIdFlag == 'insert')
                insert editIdTok;
            else if(editIdFlag == 'update')
                update editIdTok;
            
            if(reverseAppList.size()>0)
            {
                system.debug('revIdSet:'+revIdSet.size());
                
                List<Case> cList = new List<Case>();
                Map<String,Case> cMap = new Map<String,Case>();
                
                for(integer i=0;i<reverseAppList.size();i++)
                {
                    if(revIdSet.contains(reverseAppList[i].Review_ID__c))
                    {
                        Case c = new Case();
                        c.Subject = reverseAppList[i].Title__c;
                        c.Description = reverseAppList[i].Content__c;
                        //c.Origin = 'Google Play Store';
                        
                        cList.add(c);
                        cMap.put(reverseAppList[i].Review_ID__c,c);
                    }
                }
                insert cList;
                
                for(integer i=0;i<reverseAppList.size();i++)
                {
                    if(revIdSet.contains(reverseAppList[i].Review_ID__c))
                    {
                        Case c = cMap.get(reverseAppList[i].Review_ID__c);
                        reverseAppList[i].Case__c = c.Id;
                    }
                }
                insert reverseAppList;
                
                List<AppStoreReviews__c> appList = [Select Name,Author_Name__c,Title__c,Content__c,Case__c,Rating__c,App__c,Source__c,Review_ID__c,Developer_Comment__c,App_Package_Name__c,App_Image__c
                                                    from AppStoreReviews__c 
                                                    where Source__c='Google Play Store' and App_Package_Name__c=:packageName
                                                    order by Name desc limit 50  ];
                return appList;
            }
            else if(reverseAppList.size() == 0)
                return reverseAppList;
            
        }
        //system.debug('jsonResults:'+jsonResults);
        return null;
    }
    @AuraEnabled
    public static void createCaseApex(String obj)
    {
        Map<String, Object> review = (Map<String, Object>)JSON.deserializeUntyped(obj);
        String reviewId = (String)review.get('ReviewId');
        String replyText = (String)review.get('DevComment');
        String content = (String)review.get('Content');
        
        system.debug('reviewId:'+reviewId);
        system.debug('replyText:'+replyText);
        
        AppStoreReviews__c ap = [Select Id,Review_ID__c,Developer_Comment__c,Case__c from AppStoreReviews__c where Review_ID__c=:reviewId];
        
        Case c = new Case();
        c.Subject = 'Play Store Review';
        c.Description = content;
        //c.Origin = 'Google Play Store';
        insert c;
        
        ap.Case__c = c.Id;
        update ap;
    }
    @AuraEnabled
    public static boolean replyReview(String packageName, String appReview)
    {
        Google_API_Tokens__c accTok = Google_API_Tokens__c.getValues('Access Token');
        String accToken;
        
        if(accTok != null){
            accToken = accTok.Token_Value__c;
        }
        system.debug('accToken:'+accToken);
        
        system.debug('packageName:'+packageName);
        system.debug('appReview:'+appReview);
        
        //String accToken = 'a29.GlxwBVI9-MJjVgwaZjfrw1qvY2imc9-wdRgKlaz-Fi4uUsk-fDovjn7y7WYpwlhfeWFr2E4SMVp0b8SoZuhej3avvyK2bRCtvIBzrO8FJJUxLrXD3nk2xObs7yqQ3Q';
        
        Map<String, Object> review = (Map<String, Object>)JSON.deserializeUntyped(appReview);
        String reviewId = (String)review.get('ReviewId');
        String replyText = (String)review.get('DevComment');
        system.debug('reviewId:'+reviewId);
        system.debug('replyText:'+replyText);
        
        AppStoreReviews__c ap = [Select Id,Review_ID__c,Developer_Comment__c,Case__c from AppStoreReviews__c where Review_ID__c=:reviewId];
        
        if(replyText != null && reviewId != null)
        {
            String endPoint = 'https://www.googleapis.com/androidpublisher/v2/applications/'+packageName+'/reviews/'+reviewId+':reply?access_token='+accToken;
            String jsonstr = '{"replyText": "'+replyText+'"}';
            
            Http h2 = new Http();
            HttpRequest req1 = new HttpRequest();
            req1.setHeader('Content-Type','application/json');
            req1.setBody(jsonstr);
            req1.setMethod('POST');
            req1.setEndpoint(endPoint);
            HttpResponse res1 = h2.send(req1);
            system.debug('response : '+res1.getbody());
            String resp = res1.getbody();
            if(resp.contains('result'))
            {
                system.debug('in if');
                
                ap.Developer_Comment__c = replyText;
                update ap;
                system.debug('ap:'+ap);
                
                if(ap.Case__c != null)
                {
                    //post the reply to case feed 
                    ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
                    feedItemInput.subjectId = ap.Case__c;
                    
                    ConnectApi.FeedItemVisibilityType feedVisibility = ConnectApi.FeedItemVisibilityType.AllUsers;
                    feedItemInput.visibility = feedVisibility;
                    
                    
                    // The MessageBodyInput object holds the text in the post
                    ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
                    messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                    
                    ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
                    
                    //Contact contId = [select name,id from contact where id=:t.WhoId];
                    textSegmentInput = new ConnectApi.TextSegmentInput();
                    textSegmentInput.text = replyText; 
                    messageBodyInput.messageSegments.add(textSegmentInput);
                    
                    feedItemInput.body = messageBodyInput;
                    
                    ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
                    
                    return true;
                }
                return true;
            }
            else
                return false;
        }
        return false;
    }
}