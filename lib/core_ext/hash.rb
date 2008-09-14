class Hash
  def rdup
    duplicate = self.dup
    self.each_pair do |key, val|
      begin
        if val.is_a?(Array) or val.is_a?(Hash)
          duplicate[key] = val.rdup 
        else
          duplicate[key] = val.dup
        end
      rescue TypeError
        duplicate[key] = val
      end
    end
    duplicate
  end
end
