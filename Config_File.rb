module ConfigFile
  def ConfigFile.get_path
    root = Pathname.new(__FILE__).parent
    (root + 'config' + 'config.yaml.erb').to_s
  end

  def ConfigFile.read
    path = get_path
    if File.exists?(path)
      raw_data      = IO.read path
      erbified_data = ERB.new(raw_data).result
      config        = YAML.load(erbified_data) || {}
    end
  end
end
