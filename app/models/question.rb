class Question < ActiveRecord::Base

  # Extending surveyor
  include "#{self.name}Extensions".constantize if Surveyor::Config['extend'].include?(self.name.underscore)
    
  # Associations
  belongs_to :survey_section
  belongs_to :question_group
  has_many :answers, :order => "display_order ASC" # it might not always have answers
  has_one :dependency

  # Scopes
  default_scope :order => "display_order ASC"
  
  # Validations
  validates_presence_of :text, :survey_section_id, :display_order
  validates_inclusion_of :is_mandatory, :in => [true, false]
  
  # Instance Methods
  def initialize(*args)
    super(*args)
    default_args
  end
  
  def default_args
    self.is_mandatory ||= true
    self.display_type ||= "default"
    self.pick ||= "none"
  end
  
  def mandatory?
    self.is_mandatory == true
  end
  
  def dependent?
    self.dependency != nil
  end
  def triggered?(response_set)
    #dependent? ? self.dependency.is_met?(response_set) : true
    return true if !dependent? and (question_group.nil? or !question_group.dependent?)
    if dependent?
      return dependency.is_met?(response_set)
    elsif question_group.dependent?
      return question_group.dependency.is_met?(response_set)
    end
  end
  def css_class(response_set)
    [(dependent? ? "dependent" : nil), (triggered?(response_set) ? nil : "hidden"), custom_class].compact.join(" ")
  end
  
  def part_of_group?
    !self.question_group.nil?
  end

  def renderer(g = question_group)
    r = [g ? g.renderer.to_s : nil, display_type].compact.join("_")
    r.blank? ? :default : r.to_sym
  end
  
end
