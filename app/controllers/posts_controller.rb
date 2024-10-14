class PostsController < ApplicationController

  include PostsHelper

  load_and_authorize_resource

  def index
    if current_user.admin?
      @search = Post.ransack(params[:q])
      @posts = @search.result(distinct: true).order(created_at: :asc)
      @authors = User.pluck(:username, :id)
    else
      redirect_to root_path, alert: 'Доступ запрещен. Только администраторы могут просматривать все заметки.'
    end
  end

  def pending
    if current_user.admin?
      @search = Post.where(status: :pending).ransack(params[:q])
      @pending_posts = @search.result(distinct: true).order(created_at: :asc)
      render :pending_posts
    else
      redirect_to root_path, alert: 'Доступ запрещен. Только администраторы могут просматривать заметки в ожидании.'
    end
  end

  def approved
    @search = Post.where(status: :approved).ransack(params[:q])
    @approved_posts = @search.result(distinct: true).order(created_at: :asc)
    render :approved
  end

  def rejected
    if current_user.admin?
      @search = Post.where(status: :rejected).ransack(params[:q])
      @rejected_posts = @search.result(distinct: true).order(created_at: :asc)
      render :rejected
    else
      redirect_to root_path, alert: 'Доступ запрещен. Только администраторы могут просматривать отклонённые заметки.'
    end
  end

  def my_posts
    @search = current_user.posts.ransack(params[:q])
    @user_posts = @search.result(distinct: true).order(created_at: :asc)
    render :my_posts
  end

  def show
    @post = Post.find(params[:id])
  end

  def new
    @post = Post.new
    @regions = Region.all  # Получаем все регионы для формы.
  end

  def edit
    @post = Post.find(params[:id])
  end

  def update
    @post = Post.find(params[:id])

    # Удаляем выбранные изображения.
    if params[:remove_images].present?
      params[:remove_images].each do |image_id|
        attachment = @post.images.find_by(id: image_id)
        attachment.purge if attachment # Удаляем только если вложение найдено.
      end
    end

    # Удаляем выбранные файлы.
    if params[:remove_files].present?
      params[:remove_files].each do |file_id|
        attachment = @post.files.find_by(id: file_id)
        attachment.purge if attachment # Удаляем только если вложение найдено.
      end
    end

    # Прикрепляем новые изображения.
    if params[:post][:images].present?
      @post.images.attach(params[:post][:images])
    end

    # Прикрепляем новые файлы.
    if params[:post][:files].present?
      @post.files.attach(params[:post][:files])
    end

    # Пытаемся обновить пост, пропуская изображения и файлы.
    if @post.update(post_params.except(:images, :files))
      redirect_to @post, notice: 'Заметка успешно обновлена.'
    else
      render :edit
    end
  end

  def destroy
    @post = Post.find(params[:id])
    @post.destroy
    redirect_to root_path, notice: 'Заметка успешно удалена.'
  end

  def create
    if current_user.admin? # Проверяем, является ли пользователь администратором.
      @post = current_user.posts.new(post_params.merge(status: :approved)) # Создаём пост сразу со статусом approved.
    else
      @post = current_user.posts.new(post_params.merge(status: :draft)) # Для обычных пользователей по-прежнему создаём посты как draft.
    end
    if @post.save
      redirect_to @post, notice: 'Заметка успешно создана.'
    else
      render :new
    end
  end

  def send_for_approval
    @post = Post.find(params[:id])
    if current_user.can_send_for_approval?(@post)
      new_status = :pending
      PostStatusJob.perform_later(@post.id, new_status)  # Отправляем задачу на обновление статуса.

      # Обновляем статус объекта мгновенно, чтобы отражать изменения на странице.
      @post.update(status: new_status)

      flash[:notice] = 'Заметка отправлена на утверждение.'
    else
      flash[:alert] = 'Невозможно отправить заметку на утверждение.'
    end
    redirect_to my_posts_posts_path
  end

  def change_status
    @post = Post.find(params[:id])
    new_status = params[:status].to_sym

    if (@post.pending? || @post.draft?) && (new_status == :approved || new_status == :rejected)
      PostStatusJob.perform_later(@post.id, new_status)
      @post.update(status: new_status) # Обновляем статус сразу
      redirect_to @post, notice: 'Статус заметки успешно изменён.' #'Запрос на изменение статуса записи отправлен.'
    else
      redirect_to @post, alert: 'Недействительный запрос на изменение статуса.'
    end
  end

  def generate_report

    author = params[:author]
    author_status = params[:author_status]
    region = params[:region]
    post_status = params[:post_status]
    filters = params[:filters] || []

    # Конвертация строкового значения в булево.
    author_status_boolean = author_status == 'true'

    # Применение фильтров.
    @filtered_posts = Post.all
    @filtered_posts = @filtered_posts.where(region_id: region) if region.present?
    @filtered_posts = @filtered_posts.where(user_id: author) if author.present?
    @filtered_posts = @filtered_posts.joins(:user).where(users: { admin: author_status_boolean }) if author_status.present?
    @filtered_posts = @filtered_posts.where(status: post_status) if post_status.present?

    @filtered_posts.each do |post|
      images_links = post.images.attached? ? post.images.map { |image| rails_blob_path(image, only_path: true) }.join(', ') : 'Нет изображений.'
      files_links = post.files.attached? ? post.files.map { |file| rails_blob_path(file, only_path: true) }.join(', ') : 'Нет файлов.'
    end

    if @filtered_posts.present? && request.post?

      # Создание файла отчета.
      workbook = WriteXLSX.new('report.xlsx')
      worksheet = workbook.add_worksheet

      # Добавляем заголовки в файл.
      headers = ['Автор', 'Статус автора', 'Регион', 'Статус заметки', 'Заголовок', 'Текст заметки', 'Изображения', 'Файлы', 'Дата/время размещения заметки']
      worksheet.write_row(0, 0, headers)

      # Заполняем отчет данными.
      row = 1
      @filtered_posts.each do |post|
        images_links = post.images.map { |image| rails_blob_path(image, disposition: "attachment", only_path: true) }.join(', ')
        files_links = post.files.map { |file| rails_blob_path(file, disposition: "attachment", only_path: true) }.join(', ')

        worksheet.write(row, 0, post.user.username) # Автор.

        admin_status = post.user.admin? ? 'Администратор' : 'Обычный пользователь'
        worksheet.write(row, 1, admin_status) # Статус автора.

        worksheet.write(row, 2, post.region.name) # Регион.


        worksheet.write(row, 3, translate_status(post.status)) # Статус заметки.
        worksheet.write(row, 4, post.title) # Заголовок.
        worksheet.write(row, 5, post.content.to_plain_text) # Текст заметки.
        worksheet.write(row, 6, images_links) # Изображения.
        worksheet.write(row, 7, files_links) # Файлы.
        worksheet.write(row, 8, post.created_at.strftime('%Y-%m-%d %H:%M:%S')) # Дата/время размещения заметки.

        row += 1
      end

      # Закрываем и сохраняем файл.
      workbook.close

      # Отправляем файл пользователю.
      send_file 'report.xlsx', type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', x_sendfile: true
      flash[:alert] = 'Отчёт успешно создан!'
    else
      flash[:alert] = 'Нет данных для создания отчета с текущими фильтрами.'
      redirect_to posts_path
    end
  end

  private

  def post_params
    if current_user.admin?  # Если пользователь является администратором.
      params.require(:post).permit(:title, :content, :status, :region_id, images: [], files: [])
    else
      params.require(:post).permit(:title, :content, :region_id, images: [], files: [])
    end
  end

end

