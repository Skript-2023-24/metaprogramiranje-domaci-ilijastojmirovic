require "google_drive"

session = GoogleDrive::Session.from_config("config.json")

ws = session.spreadsheet_by_key("1s4gBgJFv6KmVeSQGkpKR5zcN2tJbxGRINvADiEhNgP0").worksheets[0]

dvodimenzionalni_niz = ws.rows

class Tabela
  attr_accessor :ws
  include Enumerable

  def initialize(vrednosti,ws)
    @vrednosti = vrednosti.reject do |red|
      red.all? { |celija| celija.nil? || celija.to_s.strip.empty? } ||
      red.any? { |celija| celija.to_s.downcase =~ /\b(subtotal|total)\b/ }
    end.map(&:dup)
    @ws = ws
  end

 def niz_2d
  @vrednosti
 end

  
  def red(broj_reda)
    @vrednosti[broj_reda]
  end

  def each
    @vrednosti.each do |red|
      red.each do |element|
        yield element
      end
    end
  end

  def [](kolona)
    index = @vrednosti.first.index(kolona)
    raise "Kolona ne postoji" unless index

    Kolona.new(@vrednosti, index, @ws)
  end

  def +(druga_tabela)
    if(@vrednosti.first == druga_tabela.vrednosti.first)
      nove_vrednosti = @vrednosti + druga_tabela.vrednosti.drop(1)
      Tabela.new(nove_vrednosti,@ws)
    else
      @vrednosti
    end
  end

  def -(druga_tabela)
    if(@vrednosti.first == druga_tabela.vrednosti.first)
      nove_vrednosti = @vrednosti.reject do |red|
        druga_tabela.include?(red)
      end
      Tabela.new(nove_vrednosti,@ws)
    else
      @vrednosti
    end
  end

  def method_missing(method_name, *args, &block)
    kolona = method_name.to_s.split('_').map { |w| w.capitalize }.join(' ')
    if @vrednosti.first.map(&:downcase).include?(kolona.downcase)
      index = @vrednosti.first.map(&:downcase).index(kolona.downcase)
      Kolona.new(@vrednosti, index, @ws)
    else
      super
    end
  end

  class Kolona
    include Enumerable

    def initialize(tabela, index_kolone, ws)
      @tabela = tabela
      @index_kol = index_kolone
      @ws = ws
    end

    def [](red)
      @tabela[red+1][@index_kol]
    end

    def []=(red,nova_vrednost)
      @ws[red+3, @index_kol+1] = nova_vrednost
      @ws.save
      @tabela[red+1][@index_kol]=nova_vrednost
    end

    def sum
      @tabela.drop(1).map { |red| red[@index_kol].to_i }.reduce(0, :+)
    end

    def avg
      sum.to_f / (@tabela.size - 1) # Oduzimamo 1 zbog header reda
    end

    def to_s
      stampaj.join(", ")
    end

    def stampaj
      @tabela.drop(1).map { |red| red[@index_kol] }
    end

    def each
      @tabela.drop(1).each do |red| 
        yield red[@index_kol]
      end
    end

    def map
      mapirani = []
      @tabela.drop(1).each do |red| 
        mapirani << yield(red[@index_kol])
      end
      mapirani
    end
  
    def select
      selektovani = []
      @tabela.drop(1).each do |red| 
        selektovani << red[@index_kol] if yield(red[@index_kol])
      end
      selektovani
    end
  
    def reduce(poc_vrednost)
      kolektor = poc_vrednost
      @tabela.drop(1).each do |red|
        kolektor = yield(kolektor, red[@index_kol]) 
        end
        kolektor
    end

  end

end




tabela = Tabela.new(dvodimenzionalni_niz,ws)

puts "1."
puts tabela.niz_2d

puts "------------"

puts "2. #{tabela.red(1)}"

puts "------------"

puts "3."
tabela.each do |element|
p element
end


puts "------------"

puts "5. pod 1 ->     #{tabela["Prva kolona"]}"
puts "5. pod 2 ->     #{tabela["Prva kolona"][0]}"
puts "5. pod 3 ->     #{tabela["Prva kolona"][1] = 15}"

puts "------------"

puts "6.          ->     #{tabela.prva_kolona}"
puts "6. pod i.   ->     #{tabela.prva_kolona.sum}"
puts "6. pod i.   ->     #{tabela.prva_kolona.avg}"
puts "6. pod ii.  ->     Nisam uradio"
puts "6. pod iii. ->     #{tabela.prva_kolona.select { |value| value.to_i > 20 }}"
puts "6. pod iii. ->     #{tabela.prva_kolona.reduce(0) { |sum, value| sum + value.to_i }}"

puts "7. i 10. u klasi Tabela u konstruktoru uradjeno"
