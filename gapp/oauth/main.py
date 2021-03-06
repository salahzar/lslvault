#!/usr/bin/env python
#
# This is an sample AppEngine application that shows how to 1) log in a user
# using the Twitter OAuth API and 2) extract their timeline.
#
# INSTRUCTIONS: 
#
# 1. Set up a new AppEngine application using this file, let's say on port 
# 8080. Rename this file to main.py, or alternatively modify your app.yaml 
# file.)
# 2. Fill in the application ("consumer") key and secret lines below.
# 3. Visit http://localhost:8080 and click the "login" link to be redirected
# to Twitter.com.
# 4. Once verified, you'll be redirected back to your app on localhost and
# you'll see some of your Twitter user info printed in the browser.
# 5. Copy and paste the token and secret info into this file, replacing the 
# default values for user_token and user_secret. You'll need the user's token 
# & secret info to interact with the Twitter API on their behalf from now on.
# 6. Finally, visit http://localhost:8080/timeline to see your twitter 
# timeline.
#

__author__ = "Mike Knapp"

import oauth

from google.appengine.ext import webapp
from google.appengine.ext.webapp import util
from google.appengine.api import urlfetch
from google.appengine.ext import db

class Token(db.Model):
  name = db.StringProperty(multiline=False)
  token = db.StringProperty(multiline=False)
  secret = db.StringProperty(multiline=False)  
  
class MainHandler(webapp.RequestHandler):

  def get(self, mode=""):
    
    # Your application Twitter application ("consumer") key and secret.
    # You'll need to register an application on Twitter first to get this
    # information: http://www.twitter.com/oauth
    application_key = "egK6Zj4S0HOkmfEGW7eolA" 
    application_secret = "GQEbvxW0NfmSSYrkbWPe9nyLgaJ3HeUHaJNzM0YIIk"  
    
    # Fill in the next 2 lines after you have successfully logged in to 
    # Twitter per the instructions above. This is the *user's* token and 
    # secret. You need these values to call the API on their behalf after 
    # they have logged in to your app.
    user_token = "FILL_IN"  
    user_secret = "FILL_IN"
    
    # In the real world, you'd want to edit this callback URL to point to your
    # production server. This is where the user is sent to after they have
    # authenticated with Twitter. 
    callback_url = "%s/verify?key=%s" % (self.request.host_url, self.request.get("key"))
    
    client = oauth.TwitterClient(application_key, application_secret, 
        callback_url)
    
    if mode == "login":
      return self.redirect(client.get_authorization_url())
      
    if mode == "verify":
      auth_token = self.request.get("oauth_token")
      auth_verifier = self.request.get("oauth_verifier")
      user_info = client.get_user_info(auth_token, auth_verifier=auth_verifier)
      print "Token: "+user_info["token"]+"<br>"
      print "Secret: "+user_info["secret"]+"<br>"
      key = self.request.get("key") 
      q = db.GqlQuery("SELECT * FROM Token WHERE name = :kk",kk=key)
      if(q.count(2))>0:
        results=q.fetch(10)            
        db.delete(results)
         
      newrec=Token(name=key,token=user_info["token"], secret=user_info["secret"]);
      newrec.put()
      #return self.response.out.write(user_info)
      return self.response.out.write("&token="+user_info["token"]+"&secret="+user_info["secret"]+"<br>")
      
    
    if mode == "logout":
      key = self.request.get("key") 
      q = db.GqlQuery("SELECT * FROM Token WHERE name = :kk",kk=key)
      if(q.count(2))>0:
        results=q.fetch(10)            
        db.delete(results)
      
    if mode == "timeline":
      timeline_url = "http://twitter.com/statuses/user_timeline.xml"
      result = client.make_request(url=timeline_url, token=self.request.get('token'), 
          secret=self.request.get('secret'))
      return self.response.out.write(result.content)
    
    if mode == "post":
      additional_params={}
      additional_params["status"]=self.request.get('msg')
      key= self.request.get("key") 
      q = db.GqlQuery("SELECT * FROM Token WHERE name = :kk",kk=key)
      count=q.count(2)
      if count==0 :
        return self.response.out.write('None') # Service wasn't found
      else:
        record=q.get()  #get the URL we stored previously

        post_url = "http://twitter.com/statuses/update.json"
        result = client.make_request(url=post_url, token=record.token, 
          secret=record.secret, additional_params=additional_params, method=urlfetch.POST)
        return self.response.out.write(result.content)
    
    
        
    self.response.out.write("<a href='/login'>Login via Twitter</a>")

def main():
  application = webapp.WSGIApplication([('/(.*)', MainHandler)],
                                       debug=True)
  util.run_wsgi_app(application)


if __name__ == '__main__':
  main()
