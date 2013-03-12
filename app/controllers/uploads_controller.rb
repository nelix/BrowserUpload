class UploadsController < ApplicationController
  require 'base64'
  require 'openssl'
  require 'digest/sha1'
  
  before_action :set_upload, only: [:show, :edit, :update, :destroy]
  skip_before_filter :verify_authenticity_token

  # GET /uploads
  # GET /uploads.json
  def index
    @uploads = Upload.all
  end

  # GET /uploads/1
  # GET /uploads/1.json
  def show
    # redirect_to @upload.url
  end

  # GET /uploads/new
  def new
    @callback = uploads_url
    @key = SecureRandom.base64(16).gsub(/[\/\+]/, 'X').gsub(/=+$/, '').downcase
    @policy = s3_policy(@key, AWS_BUCKET)
    @signature = s3_sign_policy(@policy, AWS_SECRET_ACCESS_KEY)
    @id = AWS_ID
  end

  # POST /uploads
  # POST /uploads.json
  def create
    @upload = Upload.new(upload_params)

    respond_to do |format|
      if @upload.save
        format.html { redirect_to @upload, notice: 'Upload was successfully created.' }
        format.json { render action: 'show', status: :created, location: @upload }
      else
        format.html { render action: 'new' }
        format.json { render json: @upload.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /uploads/1
  # PATCH/PUT /uploads/1.json
  def update
    pp params
    respond_to do |format|
      if @upload.update(upload_params)
        format.html { redirect_to @upload, notice: 'Upload was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @upload.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /uploads/1
  # DELETE /uploads/1.json
  def destroy
    # Actually removing it from amazon if left as an exercise for the reader...
    # HINT: Amazon has many libs you can use to do this.
    @upload.destroy
    respond_to do |format|
      format.html { redirect_to uploads_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_upload
      @upload = Upload.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def upload_params
      params.require(:upload).permit(:filename, :key)
    end

    def s3_policy(secret, bucket)
      policy = {
        "expiration" => 20.minutes.from_now.utc.xmlschema,
        "conditions" =>  [ 
          { "bucket" =>  bucket },
          ["starts-with", "$key", secret],
          { "acl" => "public-read" },
          ["content-length-range", 0, 20485760]
        ]
      }
      Base64.encode64(policy.to_json).gsub(/\n/, '')
    end

    def s3_sign_policy(policy_document, aws_secret_key)
      Base64.encode64(
        OpenSSL::HMAC.digest(
          OpenSSL::Digest::Digest.new('sha1'),
          aws_secret_key,
          policy_document
        )
      ).gsub("\n", "")
    end
end
