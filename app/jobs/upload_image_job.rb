require 'tmpdir'

class UploadImageJob
  @queue = :low

  def self.enqueue image
    Resque.enqueue self, image.id
  end

  def self.perform id
    image = Image.find id
    image.start_upload!

    begin
      Dir.mktmpdir do |tmp_dir|

        # download image and convert it to jpg
        tmp_image = File.join tmp_dir, 'image.jpg'
        main_image = Dragonfly.app.fetch_url(image.url).encode('jpg')
        main_image.to_file tmp_image

        # update image properties
        image.url = s3_image_url image
        image.width = main_image.width
        image.height = main_image.height
        image.content_type = 'image/jpeg'
        image.size = File.size tmp_image

        # upload image to s3
        s3_object(image).upload_file tmp_image

        # generate thumbnail
        tmp_thumbnail = File.join tmp_dir, 'thumbnail.jpg'
        thumbnail_image = Dragonfly.app.fetch_file(tmp_image).thumb('300x>').encode('jpg', '-quality 75')
        thumbnail_image.to_file tmp_thumbnail

        # update thumbnail properties
        image.thumbnail_url = s3_thumbnail_url image
        image.thumbnail_width = thumbnail_image.width
        image.thumbnail_height = thumbnail_image.height
        image.thumbnail_content_type = 'image/jpeg'
        image.thumbnail_size = File.size tmp_thumbnail

        # upload thumbnail to s3
        s3_object(image, '-thumbnail').upload_file tmp_thumbnail
      end

      image.finish_upload
      image.save!
    rescue StandardError => e
      image.reload
      image.upload_error = e.message + "\n" + e.backtrace.join("\n")
      image.fail_upload
      image.save!
    end
  end

  private

  def self.s3_object image, suffix = ''
    s3 = Aws::S3::Resource.new region: ENV['LAIR_AWS_REGION']
    s3.bucket(ENV['LAIR_AWS_DATA_BUCKET']).object "images/#{image.api_id}#{suffix}.jpg"
  end

  def self.s3_image_url image
    "#{ENV['LAIR_AWS_DATA_BUCKET_URL']}/images/#{image.api_id}.jpg"
  end

  def self.s3_thumbnail_url image
    "#{ENV['LAIR_AWS_DATA_BUCKET_URL']}/images/#{image.api_id}-thumbnail.jpg"
  end
end
