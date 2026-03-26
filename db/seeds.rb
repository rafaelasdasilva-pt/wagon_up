puts "Limpando banco de dados..."
Answer.destroy_all
Interview.destroy_all
Role.destroy_all
Analysis.destroy_all
User.destroy_all


puts "Criando usuários..."

ines = User.create!(
  name: "Inês Kaci",
  email: "ines@wagonup.com",
  password: "wagon2026",
  password_confirmation: "wagon2026"
)

clara = User.create!(
  name: "Clara Sato",
  email: "clara@wagonup.com",
  password: "wagon2026",
  password_confirmation: "wagon2026"
)

rafaela = User.create!(
  name: "Rafaela Silva",
  email: "rafaela@wagonup.com",
  password: "wagon2026",
  password_confirmation: "wagon2026"
)

gustavo = User.create!(
  name: "Gustavo Keoma",
  email: "gustavo@wagonup.com",
  password: "wagon2026",
  password_confirmation: "wagon2026"
)

puts "Usuários criados: #{User.count}"
