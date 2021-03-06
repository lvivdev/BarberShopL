#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'pony'
require 'sqlite3'

def is_barber_exists? db, name
	db.execute('select * from Barbers where name=?', [name]).length > 0
end

def seed_db db, barbers
	
	barbers.each do |barber|
		if !is_barber_exists? db, barber
			db.execute 'insert into Barbers (name) values (?)', [barber]
		end
	end

end

before do
	db = get_db
	@barbers = db.execute 'select * from Barbers'
end

configure do
  enable :sessions
end

configure do
	@db = SQLite3::Database.new 'barbershop.db'
	@db.execute 'CREATE TABLE IF NOT EXISTS
	"Users" 
	(
		"id" INTEGER PRIMARY KEY AUTOINCREMENT,
		"user" TEXT,
		"usermail" TEXT,
		"userphone" TEXT,
		"date_time" TEXT,
		"barber" TEXT,
		"color" TEXT
	)'

	@db.execute 'CREATE TABLE IF NOT EXISTS
	"Barbers" 
	(
		"id" INTEGER PRIMARY KEY AUTOINCREMENT,
		"name" TEXT
	)'

	seed_db @db, ['Walter White', 'Jessie Pinkman', 'Gus Fring', 'Mike']
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

	@db = get_db
	@db.execute "INSERT INTO
				Users
				(
					user,
					usermail,
					userphone,
					date_time,
					barber,
					color
				)
				values ( ?, ?, ?, ?, ?, ? )",
				[@user, @usermail, @userphone, @date_time, @barber, @color]

	
	
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

get('/success') do
	erb "Спасибо за обращение!"
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
    :body => "Имя: " + params[:name] + " Сообщение: " + params[:message] + " Почта: " + params[:mail],
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

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end

get '/showusers' do
	db = get_db

	@results = db.execute 'select * from Users order by id desc'
	erb :showusers

end

post '/showusers' do

end

get '/barbers' do
	db = get_db

	@barbername = db.execute 'select * from Barbers order by id desc'
	erb :barbers

end

post '/barbers' do

end	

def get_db
	db = SQLite3::Database.new 'barbershop.db'
	db.results_as_hash = true
	return db
end

