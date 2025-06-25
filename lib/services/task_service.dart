// services/task_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser!.uid;

  // Coleção de tarefas do usuário atual
  CollectionReference get _tasksCollection =>
      _firestore.collection('users').doc(_userId).collection('tasks');

  // Stream de tarefas para data específica
  Stream<List<Task>> getTasksForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _tasksCollection
        .where(
          'date',
          isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch,
        )
        .where('date', isLessThanOrEqualTo: endOfDay.millisecondsSinceEpoch)
        .snapshots()
        .map((snapshot) {
          List<Task> tasks = snapshot.docs
              .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

          // Ordenar: pendentes primeiro, depois concluídas, ambas alfabeticamente
          tasks.sort((a, b) {
            if (a.isCompleted != b.isCompleted) {
              return a.isCompleted ? 1 : -1; // Pendentes primeiro
            }
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
          });

          return tasks;
        });
  }

  // Adicionar nova tarefa
  Future<void> addTask(Task task) async {
    try {
      await _tasksCollection.doc(task.id).set(task.toMap());
    } catch (e) {
      throw Exception('Erro ao adicionar tarefa: $e');
    }
  }

  // Atualizar tarefa
  Future<void> updateTask(Task task) async {
    try {
      await _tasksCollection.doc(task.id).update(task.toMap());
    } catch (e) {
      throw Exception('Erro ao atualizar tarefa: $e');
    }
  }

  // Deletar tarefa
  Future<void> deleteTask(String taskId) async {
    try {
      await _tasksCollection.doc(taskId).delete();
    } catch (e) {
      throw Exception('Erro ao deletar tarefa: $e');
    }
  }

  // Marcar/desmarcar tarefa como concluída
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      await _tasksCollection.doc(taskId).update({'isCompleted': isCompleted});
    } catch (e) {
      throw Exception('Erro ao atualizar status da tarefa: $e');
    }
  }

  // Buscar todas as tarefas do usuário (para backup ou outras funcionalidades)
  Future<List<Task>> getAllTasks() async {
    try {
      final snapshot = await _tasksCollection.get();
      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar tarefas: $e');
    }
  }
}
