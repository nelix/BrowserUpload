class Upload < ActiveRecord::Base
	def url
		# HINT: pretty terrible.
		AWS_HOST + self.key + '/' + self.filename
	end
end
