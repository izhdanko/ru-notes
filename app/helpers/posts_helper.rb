module PostsHelper
  def translate_status(status)
    case status
    when 'draft'
      'Черновик'
    when 'pending'
      'На проверке'
    when 'approved'
      'Утверждено'
    when 'rejected'
      'Отклонено'
    else
      status
    end
  end
end
