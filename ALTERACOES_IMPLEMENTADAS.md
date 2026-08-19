# Alterações implementadas

## Edição de lançamentos

Os registros carregados das coleções `ganhos` e `gastos` agora preservam o `id` do documento do Firestore. Cada item da lista pode ser tocado ou editado pelo ícone de lápis. O diálogo permite corrigir categoria/tipo, valor e data, salvando a alteração no mesmo documento por meio de `update`.

## Despesas mensais

A tela existente de despesas fixas foi mantida e passou a ser acessível diretamente pela navegação inferior da Home. Foram adicionadas categorias específicas para `Aluguel de casa`, `Condomínio`, `Luz`, `Água`, `Internet fixa` e `Internet móvel`, além das categorias gerais já existentes. O fluxo atual de ativação, vencimento, edição e geração mensal dos lançamentos foi preservado.

## Navegação

A Home agora apresenta uma barra inferior com acesso a `Início`, `Relatórios` e `Despesas fixas`. Os dados e as coleções atuais do Firebase não foram renomeados.

## Validação

O ambiente de execução não possui Flutter ou Dart instalados, portanto não foi possível executar `flutter analyze`, testes ou build do APK. Foi realizada revisão estática dos arquivos alterados e verificação de whitespace com Git. Recomenda-se executar `flutter pub get`, `dart format lib` e `flutter analyze` no ambiente local antes de gerar o APK.

## Refatoração de nomenclatura

Foram substituídos nomes ambíguos ou inconsistentes por nomes orientados ao domínio. Exemplos: `GanhoListWidget` passou a `ListaEntradasWidget`; `GastoListWidget` passou a `ListaSaidasWidget`; `GraficosCarrosselWidget` passou a `CarrosselGraficosWidget`; `GraficoLinhaCategoria` passou a `GraficoCategoriasWidget`; `CircularMenuButton` passou a `MenuAcoesFlutuante`; `DespesasFixasPage` passou a `TelaDespesasMensais`; `ResumoFinanceiroPage` passou a `TelaResumoFinanceiro`; e `FinancialSummaryModel` passou a `ResumoFinanceiroModel`.

Os arquivos também foram renomeados para refletir suas responsabilidades. As coleções e campos persistidos no Firebase continuam com os nomes originais, como `ganhos`, `gastos`, `despesas_fixas`, `tipo`, `valor`, `data`, `fixaId` e `diaVencimento`, garantindo compatibilidade com os dados existentes.

A duplicidade de `HomePage` foi removida. A classe ficou como uma camada de compatibilidade que encaminha para `HomeScreen`, evitando duas declarações da mesma classe no mesmo arquivo.

## Dashboard baseado no mockup

A `HomeScreen` foi reconstruída como um dashboard funcional inspirado na tela aprovada. A implementação inclui saudação, seletor de data, cartão de saldo do dia, indicadores de entradas e saídas, ações rápidas, lançamentos recentes, resumo semanal e navegação inferior para relatórios e despesas fixas.

Os lançamentos recentes são carregados diretamente das coleções `ganhos` e `gastos`. O toque em um lançamento abre o formulário de edição e as ações rápidas abrem o formulário correspondente para criar uma entrada ou saída. O resumo semanal é calculado com os dados da semana da data selecionada.
