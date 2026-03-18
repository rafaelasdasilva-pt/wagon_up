puts "Limpando banco de dados..."
SuggestedRole.destroy_all
Analysis.destroy_all
User.destroy_all

# ─── Users ────────────────────────────────────────────────────────────────────

puts "Criando usuários..."

ines = User.create!(
  name: "Inês Kaci",
  email: "ines@wagoneup.com",
  password: "123456",
  password_confirmation: "123456"
)

clara = User.create!(
  name: "Clara Mendes",
  email: "clara@wagoneup.com",
  password: "123456",
  password_confirmation: "123456"
)

rafaela = User.create!(
  name: "Rafaela Silva",
  email: "rafaela@wagoneup.com",
  password: "123456",
  password_confirmation: "123456"
)

gustavo = User.create!(
  name: "Gustavo Rocha",
  email: "gustavo@wagoneup.com",
  password: "123456",
  password_confirmation: "123456"
)

# ─── Analyses ─────────────────────────────────────────────────────────────────

puts "Criando análises..."

analysis_ines = Analysis.create!(
  user: ines,
  cv_text: "Formada em Marketing pela ESPM. Dois anos como analista de dados em startup de e-commerce. Participou do bootcamp de Data Science do Le Wagon em São Paulo.",
  summary: "Profissional com background em marketing em transição para dados. Combina visão de negócio com habilidades técnicas em análise e visualização.",
  skills: "Python, SQL, pandas, Power BI, Google Analytics, Excel, storytelling com dados"
)

analysis_clara = Analysis.create!(
  user: clara,
  cv_text: "Formada em Ciências da Computação pela USP. Três anos como desenvolvedora backend em fintech. Participou do bootcamp de Web Development do Le Wagon.",
  summary: "Desenvolvedora com sólida base técnica e experiência em sistemas financeiros. Busca transição para produto ou engenharia de dados.",
  skills: "Ruby on Rails, Python, SQL, APIs REST, PostgreSQL, Git, metodologias ágeis"
)

analysis_rafaela = Analysis.create!(
  user: rafaela,
  cv_text: "Formada em Administração pela FGV. Quatro anos em consultoria estratégica. Participou do bootcamp de Data Science do Le Wagon no Rio de Janeiro.",
  summary: "Consultora com forte pensamento analítico e experiência em projetos de transformação digital. Habilidade em traduzir dados em decisões estratégicas.",
  skills: "Python, SQL, machine learning, Excel avançado, Power BI, gestão de projetos, apresentações executivas"
)

analysis_gustavo = Analysis.create!(
  user: gustavo,
  cv_text: "Formado em Design pela PUC-Rio. Cinco anos como UX Designer em agência digital. Participou do bootcamp de Web Development do Le Wagon em São Paulo.",
  summary: "Designer com foco em experiência do usuário e crescente interesse em desenvolvimento front-end. Une estética e funcionalidade em produtos digitais.",
  skills: "Figma, HTML, CSS, JavaScript, Ruby on Rails, pesquisa com usuários, prototipagem, design systems"
)

# ─── Suggested Roles ──────────────────────────────────────────────────────────

puts "Criando roles sugeridos..."

# Inês
SuggestedRole.create!(
  analysis: analysis_ines,
  position: 1,
  title: "Data Analyst",
  justification: "Seu background em marketing combinado com Python e SQL é o perfil ideal para analytics. Empresas buscam analistas que entendam o negócio E os dados.",
  market_fit: { demand: "alta", avg_salary_brl: 7500, top_companies: ["iFood", "Nubank", "Mercado Livre"] }
)

SuggestedRole.create!(
  analysis: analysis_ines,
  position: 2,
  title: "Growth Analyst",
  justification: "A combinação de marketing digital e análise de dados é exatamente o que times de growth precisam. Você fecha o ciclo entre campanha e resultado.",
  market_fit: { demand: "muito alta", avg_salary_brl: 8000, top_companies: ["Hotmart", "RD Station", "QuintoAndar"] }
)

# Clara
SuggestedRole.create!(
  analysis: analysis_clara,
  position: 1,
  title: "Engenheira de Dados",
  justification: "Sua base em computação e experiência com bancos de dados relacionais é exatamente o que times de engenharia de dados precisam para estruturar pipelines.",
  market_fit: { demand: "muito alta", avg_salary_brl: 12000, top_companies: ["Nubank", "Itaú", "Stone"] }
)

SuggestedRole.create!(
  analysis: analysis_clara,
  position: 2,
  title: "Product Engineer",
  justification: "Combina sua experiência técnica com a visão de produto que vem do trabalho em fintech. Papel cada vez mais valorizado em empresas de tecnologia.",
  market_fit: { demand: "alta", avg_salary_brl: 11000, top_companies: ["Creditas", "Loft", "Vivo"] }
)

# Rafaela
SuggestedRole.create!(
  analysis: analysis_rafaela,
  position: 1,
  title: "Analytics Manager",
  justification: "Sua experiência em consultoria aliada a machine learning posiciona você para liderar times de dados. Perfil raro e muito disputado no mercado.",
  market_fit: { demand: "alta", avg_salary_brl: 14000, top_companies: ["McKinsey", "Ambev", "Grupo Boticário"] }
)

SuggestedRole.create!(
  analysis: analysis_rafaela,
  position: 2,
  title: "Data Scientist",
  justification: "Seu background quantitativo da FGV combinado com Python e ML é a base perfeita para ciência de dados aplicada a negócios.",
  market_fit: { demand: "alta", avg_salary_brl: 11000, top_companies: ["iFood", "Magazine Luiza", "BTG Pactual"] }
)

# Gustavo
SuggestedRole.create!(
  analysis: analysis_gustavo,
  position: 1,
  title: "UX Engineer",
  justification: "A combinação rara de design e desenvolvimento front-end faz de você um candidato muito forte para times de produto que precisam fechar o gap design-dev.",
  market_fit: { demand: "muito alta", avg_salary_brl: 10000, top_companies: ["Figma", "Nubank", "Conta Azul"] }
)

SuggestedRole.create!(
  analysis: analysis_gustavo,
  position: 2,
  title: "Product Designer",
  justification: "Sua experiência sólida em UX aliada ao entendimento técnico de desenvolvimento te diferencia de designers puramente focados em visual.",
  market_fit: { demand: "alta", avg_salary_brl: 9000, top_companies: ["Totvs", "RD Station", "PagSeguro"] }
)

# ─── Confirmação ──────────────────────────────────────────────────────────────

puts ""
puts "Seed concluído!"
puts "  #{User.count} usuários criados"
puts "  #{Analysis.count} análises criadas"
puts "  #{SuggestedRole.count} roles sugeridos criados"
puts ""
puts "Logins (senha: 123456):"
User.all.each { |u| puts "  #{u.email}" }
