# OTG
execute "append dtoverlay=dwc2 to /boot/config.txt" do
  not_if "grep dtoverlay=dwc2 /boot/config.txt"
  command "echo 'dtoverlay=dwc2' >> /boot/config.txt"
end

execute "append dwc2 to /etc/modules" do
  not_if "grep dwc2 /etc/modules"
  command "echo dwc2 >> /etc/modules"
end

execute "append libcomposite to /etc/modules" do
  not_if "grep libcomposite /etc/modules"
  command "echo libcomposite >> /etc/modules"
end

# PBM
execute "Initialize PBM" do
  command <<~SHELL
    sudo mkdir -p /usr/share/pbm/shared
    wget https://gist.githubusercontent.com/jiikko/3f9fb3194c0cc7685e31fbfcb5b5f9ff/raw/23ddee29d94350be80b79d290ac3c8ce8400bd88/add_procon_gadget.sh -O /usr/share/pbm/shared/add_procon_gadget.sh
    chmod +x /usr/share/pbm/shared/add_procon_gadget.sh
 SHELL
end

# ruby
execute "Install ruby" do
  user "pi"
  not_if "rbenv versions | grep 3.2.2"
  command <<~EOH
    mkdir -p "$(rbenv root)"/plugins
    git clone https://github.com/rbenv/ruby-build.git --depth 1 "$(rbenv root)"/plugins/ruby-build
    rbenv install 3.2.2
  EOH
end
# PBMのインストール
system('sudo gem install pbmenv')

system('sudo pbmenv install latest --use')

# Ruby3.2.2を使っている場合、pbm.serviceにある3.0.1を3.2.2に置き換える
file_path = '/usr/share/pbm/current/systemd_units/pbm.service'
search_text = '3.0.1'
replace_text = '3.2.2'

content = File.read(file_path)

modified_content = content.gsub(search_text, replace_text)

File.write(file_path, modified_content)

file_path = '/usr/share/pbm/current/systemd_units/pbm_web.service'
search_text = '3.0.1'
replace_text = '3.2.2'

content = File.read(file_path)

modified_content = content.gsub(search_text, replace_text)

File.write(file_path, modified_content)

# gadget.shを実行するためのファイルをダウンロード
require 'net/http'

url = 'https://raw.githubusercontent.com/kanetsugu0609/gadget.sh/main/gadget.rb'
save_path = File.expand_path('gadget.rb', '~/')

uri = URI(url)
response = Net::HTTP.get_response(uri)

if response.code == '200'
  File.open(save_path, 'wb') do |file|
    file.write(response.body)
  end
  puts 'ファイルをダウンロードしました。'
else
  puts "ファイルのダウンロードに失敗しました。"
end

system('sudo systemctl link /usr/share/pbm/current/systemd_units/pbm.service')

system('sudo systemctl enable pbm.service')

system("sudo sed -i 's/# config.api_servers/config.api_servers/' /usr/share/pbm/current/app.rb")

run_command 'sudo systemctl disable triggerhappy.socket'

run_command 'sudo systemctl disable triggerhappy.service'

run_command 'sudo systemctl disable bluetooth'

run_command 'sudo systemctl disable apt-daily-upgrade.timer'

run_command 'sudo systemctl disable apt-daily.timer'

system('cat /usr/share/pbm/current/device_id')

system('sudo reboot')
