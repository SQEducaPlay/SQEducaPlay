import 'school_model.dart';

class SchoolService {
  // Usando um Singleton para manter os dados em memória durante a execução do app.
  static final SchoolService _instance = SchoolService._internal();
  factory SchoolService() => _instance;
  SchoolService._internal() {
    _initializeSchools();
  }

  final List<School> _schools = [];

  // Inicializa com escolas municipais de Saquarema-RJ
  void _initializeSchools() {
    _schools.addAll([
      School(
        id: '1',
        name: 'E.M. Professora Maria da Glória Braga Ribeiro',
        address: 'Barra Nova',
        city: 'Saquarema',
      ),
      School(
        id: '2',
        name: 'E.M. Professora Mariléa Venâncio',
        address: 'Bacaxá',
        city: 'Saquarema',
      ),
      School(
        id: '3',
        name: 'E.M. Professora Hilda Rabello Marques',
        address: 'Sampaio Correia',
        city: 'Saquarema',
      ),
      School(
        id: '4',
        name: 'E.M. Doutor Luiz Alfredo Gomes de Noronha',
        address: 'Boqueirão',
        city: 'Saquarema',
      ),
      School(
        id: '5',
        name: 'E.M. Professora Altamira Barcellos',
        address: 'Vilatur',
        city: 'Saquarema',
      ),
      School(
        id: '6',
        name: 'E.M. Professor Levi Carneiro',
        address: 'Rio da Areia',
        city: 'Saquarema',
      ),
      School(
        id: '7',
        name: 'E.M. Professora Maria Amália de Brito',
        address: 'Jaconé',
        city: 'Saquarema',
      ),
      School(
        id: '8',
        name: 'E.M. Nossa Senhora de Nazaré',
        address: 'Centro',
        city: 'Saquarema',
      ),
      School(
        id: '9',
        name: 'E.M. Joaquim Lavoura',
        address: 'Rio Seco',
        city: 'Saquarema',
      ),
      School(
        id: '10',
        name: 'E.M. Professor Dario Soares Ferreira',
        address: 'Tingui',
        city: 'Saquarema',
      ),
      School(
        id: '11',
        name: 'E.M. Prefeito Antônio Francisco da Silva',
        address: 'Itaúna',
        city: 'Saquarema',
      ),
      School(
        id: '12',
        name: 'E.M. Professora Noraldina dos Santos Freitas',
        address: 'Porto da Roça',
        city: 'Saquarema',
      ),
      School(
        id: '13',
        name: 'E.M. Professora Rosalina de Jesus Gaspar',
        address: 'Mumbuca',
        city: 'Saquarema',
      ),
      School(
        id: '14',
        name: 'E.M. Professor Raul Lopes',
        address: 'Palmital',
        city: 'Saquarema',
      ),
      School(
        id: '15',
        name: 'E.M. Professora Maria Soares da Costa',
        address: 'Rio Mole',
        city: 'Saquarema',
      ),
      School(
        id: '16',
        name: 'E.M. Vereador José Alfredo Gaspar',
        address: 'Jardim Ipitangas',
        city: 'Saquarema',
      ),
      School(
        id: '17',
        name: 'E.M. Professora Mércia Viana de Souza',
        address: 'Sampaio Correia',
        city: 'Saquarema',
      ),
      School(
        id: '18',
        name: 'E.M. Professor Alcides Rodrigues Caminha',
        address: 'Vila Verde',
        city: 'Saquarema',
      ),
      School(
        id: '19',
        name: 'E.M. Professor Jether Monteiro',
        address: 'Jaconé',
        city: 'Saquarema',
      ),
      School(
        id: '20',
        name: 'E.M. Professora Maria Vitória Maia',
        address: 'Vilatur',
        city: 'Saquarema',
      ),
      School(
        id: '21',
        name: 'E.M. Manoel Muniz',
        address: 'Barreira',
        city: 'Saquarema',
      ),
    ]);
  }

  // Retorna todas as escolas cadastradas
  List<School> getAllSchools() {
    return List.unmodifiable(_schools);
  }

  // Busca uma escola pelo ID
  School? getSchoolById(String id) {
    try {
      return _schools.firstWhere((school) => school.id == id);
    } catch (e) {
      return null;
    }
  }

  // Adiciona uma nova escola
  void addSchool(School school) {
    _schools.add(school);
  }

  // Remove uma escola
  void removeSchool(String id) {
    _schools.removeWhere((school) => school.id == id);
  }
}
