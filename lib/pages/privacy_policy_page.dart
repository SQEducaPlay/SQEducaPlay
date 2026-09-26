import 'package:flutter/material.dart';

import '../config/privacy_policy_config.dart';
import '../widgets/app_bar.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const policyVersion = PrivacyPolicyConfig.version;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        title: 'Aviso de privacidade',
        showProfileAvatar: false,
      ),
      body: const SelectionArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Versao $policyVersion',
                style: TextStyle(color: Colors.black54),
              ),
              SizedBox(height: 16),
              Text(
                'Piloto demonstrativo',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'O SQEducaPlay desta versao e um piloto independente e nao representa '
                'homologacao ou parceria com a Prefeitura de Saquarema. Ate a definicao '
                'formal do controlador e das responsabilidades, utilize somente dados ficticios.',
              ),
              SizedBox(height: 20),
              Text(
                'Dados tratados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Nome, apelido opcional, identificador de acesso, senha protegida por hash '
                'para autenticacao, nome do responsavel, escola, turma, ano escolar, respostas, '
                'pontuacao, progresso e registros tecnicos de seguranca. Se a opcao Salvar acesso '
                'for marcada, a senha tambem fica armazenada localmente para preenchimento '
                'automatico e pode ser removida desmarcando essa opcao. A foto de perfil e '
                'opcional e pode ser selecionada na galeria ou capturada pela camera. O app nao '
                'solicita localizacao nem contatos.',
              ),
              SizedBox(height: 20),
              Text(
                'Finalidades',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Autenticar o usuario, oferecer atividades de Portugues e Matematica, '
                'registrar aprendizagem e permitir acompanhamento somente por profissionais autorizados.',
              ),
              SizedBox(height: 20),
              Text(
                'Protecao e compartilhamento',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'No modo local, os dados ficam no armazenamento do dispositivo. Na web, '
                'o modo local demonstrativo mantem dados temporariamente em memoria no navegador. '
                'Quando o acesso online estiver habilitado, o e-mail do responsavel, os perfis '
                'familiares e os registros de quizzes podem ser enviados ao Supabase para permitir '
                'sincronizacao entre aparelhos. O acesso aos registros e limitado por autenticacao '
                'e politicas no banco; a conexao usa HTTPS e o provedor aplica criptografia de '
                'infraestrutura. Isso nao e criptografia ponta a ponta: o operador do projeto pode '
                'administrar o banco. Dados nao devem ser vendidos nem usados para anuncios.',
              ),
              SizedBox(height: 20),
              Text(
                'Direitos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Na tela Privacidade, o titular ou responsavel pode copiar os dados locais '
                'e solicitar a exclusao da conta. Correcao, oposicao, retirada de consentimento '
                'e atendimento institucional dependem de canais que ainda devem ser formalmente '
                'definidos antes de qualquer uso real.',
              ),
              SizedBox(height: 20),
              Text(
                'Pendencia institucional',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'O acesso online permanece em teste. Nao informe dados identificaveis de menores '
                'ate que o responsavel pelo projeto aprove e publique: controlador, encarregado/'
                'canal LGPD, bases legais, prazos de retencao, operadores, processo de incidente '
                'e data de vigencia. Use perfis de teste sem nomes, fotos ou informacoes reais.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
