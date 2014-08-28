class ApiController < ApplicationController
  protect_from_forgery with: :null_session  
  
  before_action :signup_key_verification, :only => [:signup, :signin, :get_token]
  
  def signup
    if request.post?
      if params && params[:full_name] && params[:email] && params[:password]
        
        params[:user] = Hash.new    
        params[:user][:first_name] = params[:full_name].split(" ").first
        params[:user][:last_name] = params[:full_name].split(" ").last
        params[:user][:email] = params[:email]
        params[:user][:password] = params[:password]    
        params[:user][:verification_code] = rand_string(20)

        @user = User.new(user_params)

        if @user.save
          render :json => @user.to_json, :status => 200
        else
          error_str = ""

          @user.errors.each{|attr, msg|           
            error_str += "#{attr} - #{msg},"
          }
                    
          e = Error.new(:status => 400, :message => error_str)
          render :json => e.to_json, :status => 400
        end
      else
        e = Error.new(:status => 400, :message => "required parameters are missing")
        render :json => e.to_json, :status => 400
      end
    end
  end

  def signin
    if request.post?
      if params && params[:email] && params[:password]      
        user = User.where(:email => params[:email]).first
      
        if user         
            if User.authenticate(params[:email], params[:password])            
              if !user.authtoken_expiry || user.authtoken_expiry < Time.now
                auth_token = rand_string(20)
                auth_expiry = Time.now + (24*60*60)
          
                user.update_attributes(:api_authtoken => auth_token, :authtoken_expiry => auth_expiry)          
              end 
            
              render :json => user.to_json, :status => 200
            else
              e = Error.new(:status => 401, :message => "Wrong Password")
              render :json => e.to_json, :status => 401
            end
        else
          e = Error.new(:status => 400, :message => "No user record found for this email ID")
          render :json => e.to_json, :status => 400
        end
      else
        e = Error.new(:status => 400, :message => "required parameters are missing")
        render :json => e.to_json, :status => 400
      end
    end    
  end
  
  def reset_password
    if params && params[:authtoken] && params[:email] && params[:old_password] && params[:new_password]   
      user = User.where(:email => params[:email]).first
      
      if user         
        if user.api_authtoken == params[:authtoken] && user.authtoken_expiry > Time.now
          if User.authenticate(params[:email], params[:old_password])  
            auth_token = rand_string(20)
            auth_expiry = Time.now + (24*60*60)
                      
            user.update_attributes(:password => params[:new_password], :api_authtoken => auth_token, :authtoken_expiry => auth_expiry)
            render :json => user.to_json, :status => 200
            
            # m = Message.new(:status => 200, :message => "Password is being reset!")
            # render :json => m.to_json, :status => 200            
          else
            e = Error.new(:status => 401, :message => "Wrong Password")
            render :json => e.to_json, :status => 401
          end
        else
          e = Error.new(:status => 401, :message => "Authtoken is invalid or has expired. Kindly refresh the token and try again!")
          render :json => e.to_json, :status => 401
        end
      else
        e = Error.new(:status => 400, :message => "No user record found for this email ID")
        render :json => e.to_json, :status => 400
      end
    else
      e = Error.new(:status => 400, :message => "required parameters are missing")
      render :json => e.to_json, :status => 400
    end
  end
  
  def get_token
    if params && params[:email]    
      user = User.where(:email => params[:email]).first
    
      if user 
        if !user.authtoken_expiry || user.authtoken_expiry < Time.now
          auth_token = rand_string(20)
          auth_expiry = Time.now + (24*60*60)
          
          user.update_attributes(:api_authtoken => auth_token, :authtoken_expiry => auth_expiry)          
        end        
        
        render :json => user.to_json(:only => [:api_authtoken, :authtoken_expiry])                
      else
        e = Error.new(:status => 400, :message => "No user record found for this email ID")
        render :json => e.to_json, :status => 400
      end
      
    else
      e = Error.new(:status => 400, :message => "required parameters are missing")
      render :json => e.to_json, :status => 400
    end
  end

  def clear_token
    if params && params[:authtoken] && params[:email]    
      user = User.where(:email => params[:email]).first
      
      if user         
        if user.api_authtoken == params[:authtoken] && user.authtoken_expiry > Time.now
          user.update_attributes(:api_authtoken => nil, :authtoken_expiry => nil)
          
          m = Message.new(:status => 200, :message => "Token is being cleared!")          
          render :json => m.to_json, :status => 200  
        else
          e = Error.new(:status => 401, :message => "Authtoken is invalid or has expired. Kindly refresh the token and try again!")
          render :json => e.to_json, :status => 401
        end
      else
        e = Error.new(:status => 400, :message => "No user record found for this email ID")
        render :json => e.to_json, :status => 400
      end
    else
      e = Error.new(:status => 400, :message => "required parameters are missing")
      render :json => e.to_json, :status => 400
    end
  end
  
  def upload_photo
    
  end

  def delete_photo
    
  end

  def get_photos
    
  end

  private 
  
  def signup_key_verification
    if !(params[:api_key] == "tUklCPqBvhubzzYoaXKzEKLJgWHFNVcNijJuqlxCP" && 
      params[:api_secret] == "VbxtrVWXefFBUGcOaCLNNpkLneXaqiNfJbLYrBIjc")
      
      e = Error.new(:status => 401, :message => "API credentials are missing or invalid")
      render :json => e.to_json, :status => 401
    end
  end
  
  def rand_string(len)
    o =  [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
    string  =  (0..len).map{ o[rand(o.length)]  }.join

    return string
  end

  def rand_num(len)
    o =  [('0'..'9')].map{|i| i.to_a}.flatten
    number  =  (0..len).map{ o[rand(o.length)]  }.join

    return number
  end
  
  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_hash, :password_salt, :verification_code, 
    :email_verification, :api_authtoken, :authtoken_expiry)
  end
end