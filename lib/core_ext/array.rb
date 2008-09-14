class Array
  def rdup
    duplicate = []
    self.each do |e|
      begin
        if e.is_a?(Array) or e.is_a?(Hash)
          duplicate << e.rdup 
        else
          # this doesn't work - e.g. "true" has public method "dup" but still can't be duped
          # if e.public_methods.include?("dup")
          duplicate << e.dup
        end
      rescue TypeError
        duplicate << e
      end
    end
    duplicate
  end
end
