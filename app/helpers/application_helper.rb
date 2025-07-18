module ApplicationHelper
  def notification_classes(type)
    case type.to_s
    when 'success'
      'bg-green-900/80 border-green-500/30'
    when 'error', 'alert'
      'bg-red-900/80 border-red-500/30'
    when 'warning'
      'bg-yellow-900/80 border-yellow-500/30'
    else # 'info' or default
      'bg-blue-900/80 border-blue-500/30'
    end
  end

  def notification_icon(type)
    case type.to_s
    when 'success'
      content_tag(:i, '', 'data-lucide': 'check-circle', class: 'h-5 w-5 text-green-400')
    when 'error', 'alert'
      content_tag(:i, '', 'data-lucide': 'alert-triangle', class: 'h-5 w-5 text-red-400')
    when 'warning'
      content_tag(:i, '', 'data-lucide': 'alert-circle', class: 'h-5 w-5 text-yellow-400')
    else # 'info' or default
      content_tag(:i, '', 'data-lucide': 'info', class: 'h-5 w-5 text-blue-400')
    end
  end
end
