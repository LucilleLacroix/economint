class Category < ApplicationRecord
  belongs_to :user
  has_many :expenses, dependent: :destroy

    before_create :set_default_color

  private

  def set_default_color
    return if color.present?

    palette = [
      "#A3C4F3", # bleu pastel
      "#CDB4DB", # violet doux
      "#FFC8DD", # rose clair
      "#FFAFCC", # rose corail
      "#B5EAD7", # vert menthe pastel
      "#9BF6FF", # bleu ciel lumineux
      "#B28DFF", # violet lavande
      "#FFD6A5", # pêche pastel
      "#D0A5F2", # mauve tendre
      "#A0E7E5", # turquoise pastel
      "#FFB5E8", # rose bonbon clair
      "#CDE7F0"  # bleu givré très doux
    ]

    self.color = palette.sample
  end
end
