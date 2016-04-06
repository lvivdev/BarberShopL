#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'pony'



configure do
  enable :sessions
end

configure do
	@db = SQLite3::Database.new 'barbershop.db'
	@db.execute 'CREATE TABLE IF NOT EXISTS 
	"Users"
	(
		"id" INTEGER PRIMARY KEY AUTOINCREMENT,
		"username" TEXT,
		"phone" TEXT,
		"date_stamp" TEXT,
		"barber" TEXT,
		"color" TEXT
	)'
end

helpers do
  def username
    session[:identity] ? session[:identity] : "#{@username}"
  end
end

before '/login/form/*' do
  unless session[:identity]
    session[:previous_url] = request.path
    @error = 'Sorry, you need to be logged in to visit ' + request.path
    halt erb(:login_form)
  end
end

get '/' do
	erb "Мы приветствуем Вас в нашем Barber Shop! Осмотритесь тут пока)"		
end

get '/login/form' do
  erb :login_form
end

post '/login/attempt' do
	@username = params[:username]
	@pass = params[:pass]
	if @username == 'admin' && @pass == 'pass'
		session[:identity] = @username
		where_user_came_from = session[:previous_url] || '/'
		redirect to where_user_came_from
	else
		erb :login_form
	end
end

get '/about' do
	erb :about
end

get '/visit' do
	erb :visit
end

post '/visit' do
	@user = params[:user]
	@usermail = params[:usermail]
	@userphone = params[:userphone]
	@date_time = params[:date_time]
	@barber = params[:barber]
	@color = params[:color]

	#create hash
	hh = {
		:user => 'Введите имя',
		:usermail => 'Введите почту',
		:userphone => 'Что-то не так с телефоном',
		:date_time => 'Время тоже неверно'
	}

	@error = hh.select {|key,_| params[key] == ""}.values.join(", ")

	if @error != ''
		return erb :visit		
	end

	f = File.open './public/users.txt', 'a'
	f.write "Barber: #{@barber} for User: #{@user}, Mail: #{@usermail}, Phone: #{@userphone}, Date and time: #{@date_time}, Цвет стрижки: #{@color}"
	f.close

	Pony.mail({
	:from => params[:user],
    :to => 'klrealty.rs@gmail.com',
    :subject => params[:user] + " has contacted you via the Website",
    :body => "Name: " + params[:user] + " " + "Mail: " + params[:usermail] + " " +  "Phone: " + params[:userphone] + " " +  "Date and time: " + params[:date_time] + " " +  "Barber: " + params[:barber] + " " +  "Color: " + params[:color],
    :via => :smtp,
    :via_options => {
     :address              => 'smtp.gmail.com',
     :port                 => '587',
     :enable_starttls_auto => true,
     :user_name            => 'klrealty.rs@gmail.com',
     :password             => '81caeb71a2019fbb7ada016b85d040de',
     :authentication       => :login, 
     :domain               => "localhost.localdomain" 
     }
    })
    redirect '/success' 
end

get '/contacts' do
	erb :contacts, :layout => :layout
end

post '/contacts' do

	@name = params[:name]
	@mail = params[:mail]
	@message = params[:message]

	#create hash to define error messages
	hash = {
		:name => 'Введите имя',
		:mail => 'Введите почту',
		:message => 'Введите сообщение'
	}

	#присвоить переменной error значение value из массива hash. Выводить все ошибки.
	@error = hash.select{|key,_| params[key] == ''}.values.join(", ")

	if @error != ''
		return erb :contacts
	end

	c = File.open './public/contacts.txt', 'a'
	c.write "User: #{@name}, Mail: #{@mail}, Message: #{@message} "
	c.close

	Pony.mail({
	:from => params[:name],
    :to => 'klrealty.rs@gmail.com',
    :subject => params[:name] + " has contacted you via the Website",
    :body => "Сообщение: " + " " + params[:message] + " " + " Почта: " + params[:mail],
    :via => :smtp,
    :via_options => {
     :address              => 'smtp.gmail.com',
     :port                 => '587',
     :enable_starttls_auto => true,
     :user_name            => 'klrealty.rs@gmail.com',
     :password             => '81caeb71a2019fbb7ada016b85d040de',
     :authentication       => :login, 
     :domain               => "localhost.localdomain" 
     }
    })
    redirect '/success' 
end

get('/success') do
	erb "Спасибо за обращение!"
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end



