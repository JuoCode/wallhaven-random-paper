require 'nokogiri'
require 'open-uri'
require 'FileUtils'
require 'json'

DB_FILE = File.expand_path('~') + '/.wallhaven.db'

FileUtils.touch DB_FILE

file_content = File.read(DB_FILE)
file_content = '[]' if file_content.empty?

db = JSON.parse(file_content)

# arg = "{query}"
arg = "bed"

# 
# 根据关键字查询并抓取图片
# 
define_method :fetch_wallpaper do |search|
  p "fetch wallpaper: #{search}"
  base_url = "http://alpha.wallhaven.cc/search?q=#{search}"
  
  doc = Nokogiri::HTML(open(base_url))

  thumbs = doc.css(".thumbs-container ul li .preview")

  if thumbs.empty?
    p 'Not Found'
  else
    id = thumbs.to_a.sample.attributes['href'].value.split('/').last

    wallpaper_url = "http://alpha.wallhaven.cc/wallpaper/#{id}"

    wallpaper_doc = Nokogiri::HTML(open(wallpaper_url))
    real_url = "http:" + wallpaper_doc.css('#wallpaper')[0].attributes['src'].value

    # p real_url
    file_name = real_url.split('/').last

    tmp_file = "/tmp/#{file_name}"
    open(tmp_file, 'wb') do |file|
      file << open(real_url).read
    end

    script = <<-eos
      osascript -e 'tell application \"Finder\" to set desktop picture to POSIX     file \"#{tmp_file}\"'
    eos

    # 把 id 保存到文件里面
    db.push tmp_file
    File.open(DB_FILE,"w") do |f|
      f.write(db.to_json)
    end

    system script

    # FileUtils.rm(tmp_file)
    
    p "壁纸 ID: #{id.to_i}"

  end
end

# 
# 复制当前壁纸文件到桌面
# 
define_method :copy_to_desktop do
  p "Like it"
  tmp_file = db.last
  # p tmp_file
  dist_file = File.expand_path('~') + '/Desktop/' + File.basename(tmp_file)
  # p dist_file
  FileUtils.cp tmp_file, dist_file
end


if arg == 'like'
  copy_to_desktop
else
  fetch_wallpaper arg
end


