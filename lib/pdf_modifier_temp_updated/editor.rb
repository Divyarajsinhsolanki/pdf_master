module PdfModifier
  # ✅ add_text(input_pdf, output_pdf, text, x, y, page_number): Insert text at a specific position.
  # ✅ add_watermark(input_pdf, output_pdf, watermark_text): Apply a watermark.
  # ✅ add_signature(input_pdf, output_pdf, signature_image, x, y, page_number): Add a signature image.
  # ✅ redact_text(input_pdf, output_pdf, text_to_remove): Find and remove sensitive text.


  def self.user_access_reports(sftp_upload = true, email_notification = true)
    csv_generated_successfully = true
    begin
      puts "Starting User Access Report generation...".blue
      time = Time.now.utc
      environment_name = URI(SITE_BASE_URL).host.split('.').first
      # Define file name and path
      file_name = "User_access_report_MyForms_#{environment_name}_#{time.strftime('%Y%m%d%H%M%S')}.csv"
      file_path = "#{PRIVATE_FILE_PATH}/exports/user_access_reports/#{file_name}"
      system("mkdir -p #{PRIVATE_FILE_PATH}/exports/user_access_reports")

      CSV.open(file_path, 'wb') do |csv|
        headers = ['Employee First Name', 'Employee Last Name', 'Employee Email ID', 'Login ID', 'Company Name', 'Company Type (MyForms/eForms)', 'Brightree Company Name', 'Login Created Date', 'Last Authentication Date', 'Employee Access Status', 'MCU User', 'Login Medium'] + ROLES_LIST
        csv << headers

        active_companies = Company.get_rts_companies.where(status: 'ACTIVE')
        puts "Found #{active_companies.size} active RTS companies".green

        active_companies.each do |company|
          puts "Generating report for company: #{company.organization_name}, ID: #{company.id}".yellow
          if company.organization_name.match?(Regexp.union(COMPANY_NAME.map(&:downcase))) || company.external_site_database&.match?(Regexp.union(BRIGHTREE_COMPANY_NAME.map(&:downcase)))
            active_users = company.users.where(status: 'ACTIVE')
          else
            email_conditions = EMAIL_DOMAIN.map { |domain| "users.email_address LIKE '%@#{domain}'" }.join(" OR ")
            begin
              active_users = company.users.joins(:roles).where("users.status = ? AND (#{email_conditions} OR roles.name IN (?))", 'ACTIVE', ROLES).distinct
            rescue
              active_users = User.joins("INNER JOIN user_companies uc on uc.user_id = users.id INNER JOIN roles_users ON roles_users.user_id = users.id INNER JOIN roles ON roles.id = roles_users.role_id").where("uc.company_id = #{company.id} AND users.status = ? AND (#{email_conditions} OR roles.name IN (?))", 'ACTIVE', ROLES).includes(:user_companies, :user_brightree_credentials, :roles, :user_logins).distinct
            end
          end
          puts "Found #{active_users.size} active users for company: #{company.organization_name}".yellow

          # Populate CSV with user data
          active_users.each do |user|
            user_company = user.user_companies.find { |uc| uc[:company_id] == company.id }
            login_credential = user.user_brightree_credentials.find { |cred| cred[:company_id] == company.id }
            user_login = user.user_logins.find { |login| login[:company_id] == company.id }

            first_name = user.first_name
            last_name = user.last_name
            email_address = user.email_address
            login_id = login_credential&.brightree_username
            company_name = company.organization_name
            company_type = company.is_eforms_enabled? ? 'eForms' : 'MyForms'
            brightree_company_name = company.external_site_database
            created_at = user.created_at&.strftime('%m/%d/%Y')
            last_login = user_company&.last_login_at&.strftime('%m/%d/%Y')
            access_status = user_company&.status
            is_mcu_user = user.user_companies.find { |uc| uc[:company_id] != company.id }.present? ? 'Yes' : 'No'
            login_medium = user_login&.login_medium
            role_names = user.roles.map { |role| role.name.downcase.gsub('_', ' ') }.uniq
            role_values = ROLES_LIST.map { |role| role_names.include?(role.downcase) ? 'Yes' : 'No' }

            csv << [first_name, last_name, email_address, login_id, company_name, company_type, brightree_company_name, created_at, last_login, access_status, is_mcu_user, login_medium] + role_values
          end
          puts "Finished process for company: #{company.organization_name}, ID: #{company.id}".green
        end
      end
      puts "User Access Report generation completed successfully.".green
    rescue => e
      csv_generated_successfully = false
      puts "An error occurred while generating the User Access Report: #{e.message}".red
      log_error('User Access Report Exception', _FILE_, _LINE_, e)
      Notifications.user_access_report_notification('failure', file_name, environment_name, 'Generation Error' ).deliver if email_notification
    end
    # Send to SFTP
    if csv_generated_successfully
      if sftp_upload
        upload_to_sftp(file_path, file_name, environment_name, email_notification)
      else
        puts "Skipping SFTP upload as per request".yellow
      end
    else
      puts "Skipping SFTP upload due to CSV generation error".red
    end
  end


  
  class Editor
    # Add text to a specific position in a PDF
    def self.add_text(input_pdf, output_pdf, text, x, y, page_number)
      pdf = CombinePDF.load(input_pdf)
    
      return unless page_number.between?(1, pdf.pages.count) # Ensure page number is valid

      # Create a temporary overlay PDF with the same page size
      temp_pdf = "temp_overlay.pdf"
      Prawn::Document.generate(temp_pdf, margin: 0, page_size: [pdf.pages[0][:MediaBox][2], pdf.pages[0][:MediaBox][3]]) do
        draw_text text, at: [x, y]
      end
    
      # Load overlay and apply only to the specified page
      overlay_pdf = CombinePDF.load(temp_pdf)
      pdf.pages[page_number - 1] << overlay_pdf.pages[0] # Merge overlay with the specified page
    
      pdf.save(output_pdf)
      File.delete(temp_pdf) if File.exist?(temp_pdf) # Clean up temporary file
    end

    # Add a watermark to each page in a PDF
    def self.add_watermark(input_pdf, output_pdf, watermark_text)
      temp_pdf = "temp_watermark.pdf"

      Prawn::Document.generate(temp_pdf, margin: 0) do
        text watermark_text, size: 50, align: :center, valign: :center, rotate: 45, opacity: 0.3
      end

      pdf = CombinePDF.load(input_pdf)
      watermark = CombinePDF.load(temp_pdf)

      pdf.pages.each { |page| page << watermark.pages[0] }

      pdf.save(output_pdf)
      File.delete(temp_pdf) if File.exist?(temp_pdf)
    end
  end
end