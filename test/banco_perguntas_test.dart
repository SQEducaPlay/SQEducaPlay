import 'package:flutter_test/flutter_test.dart';
import 'package:sqeducaplay/banco_perguntas.dart';

void main() {
  test('classifica perguntas conforme o ano escolar', () {
    final faceis = BancoPerguntas.buscarPerguntas(
      'Matemática',
      '2º Ano Fundamental',
      'Números até 1000',
    );
    final medias = BancoPerguntas.buscarPerguntas(
      'Matemática',
      '3º Ano Fundamental',
      'Divisão',
    );
    final dificeis = BancoPerguntas.buscarPerguntas(
      'Matemática',
      '5º Ano Fundamental',
      'Frações',
    );

    expect(faceis, isNotEmpty);
    expect(
      faceis.every((question) => question['dificuldade'] == 'facil'),
      isTrue,
    );
    expect(
      medias.every((question) => question['dificuldade'] == 'media'),
      isTrue,
    );
    expect(
      dificeis.every((question) => question['dificuldade'] == 'dificil'),
      isTrue,
    );
  });
}
