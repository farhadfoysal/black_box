import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/task/task_model.dart';
import '../../task/tasks_repository.dart';

class TasksController extends GetxController {
  final tasks = <TaskModel>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;
  final repository = TasksRepository();

  void createNewTask({
    required String title,
    required String description,
    required Color color,
    required DateTime dueAt,
  }) {
    final newTask = TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate a unique ID based on timestamp
      uid: 'current_user_id', // Replace with the actual user ID (e.g., from auth state)
      title: title,
      description: description,
      color: color,
      dueAt: dueAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: 0, // Set false initially; update after syncing with the server
    );

    tasks.add(newTask);
  }


  /// Fetch tasks for a specific date.
  Future<void> fetchTasks({required DateTime date}) async {
    try {
      isLoading.value = true;
      error.value = '';

      final fetchedTasks = await repository.getTasks();
      tasks.assignAll(
        fetchedTasks.where((task) {
          return DateFormat('d').format(task.dueAt) == DateFormat('d').format(date) &&
              date.month == task.dueAt.month &&
              date.year == task.dueAt.year;
        }).toList(),
      );
    } catch (e) {
      error.value = 'Failed to load tasks: $e';
      Get.snackbar('Error', error.value);
    } finally {
      isLoading.value = false;
    }
  }

  /// Add a new task.
  Future<void> addTask({
    required String uid,
    required String title,
    required String description,
    required Color color,
    required DateTime dueAt,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final newTask = TaskModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        uid: uid,
        title: title,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueAt: dueAt,
        color: color,
        isSynced: 0,
      );

      await repository.insertTask(newTask);
      tasks.add(newTask);
      Get.snackbar('Success', 'Task added successfully!');
    } catch (e) {
      error.value = 'Failed to add task: $e';
      Get.snackbar('Error', error.value);
    } finally {
      isLoading.value = false;
    }
  }

  /// Sync unsynced tasks.
  Future<void> syncTasks() async {
    try {
      isLoading.value = true;
      error.value = '';

      final unsyncedTasks = await repository.getUnsyncedTasks();
      for (final task in unsyncedTasks) {
        // Simulate server sync (replace with actual API call)
        await Future.delayed(const Duration(milliseconds: 500));
        await repository.updateRowValue(task.id, 1); // Mark as synced
      }

      tasks.assignAll(await repository.getTasks());
      Get.snackbar('Success', 'Tasks synced successfully!');
    } catch (e) {
      error.value = 'Failed to sync tasks: $e';
      Get.snackbar('Error', error.value);
    } finally {
      isLoading.value = false;
    }
  }

  /// Update an existing task.
  Future<void> updateTask(TaskModel updatedTask) async {
    try {
      isLoading.value = true;
      error.value = '';

      await repository.insertTask(updatedTask);
      final index = tasks.indexWhere((task) => task.id == updatedTask.id);
      if (index != -1) {
        tasks[index] = updatedTask;
      }
      Get.snackbar('Success', 'Task updated successfully!');
    } catch (e) {
      error.value = 'Failed to update task: $e';
      Get.snackbar('Error', error.value);
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete a task by ID.
  Future<void> deleteTask(String taskId) async {
    try {
      isLoading.value = true;
      error.value = '';

      await repository.deleteTask(taskId);
      tasks.removeWhere((task) => task.id == taskId);
      Get.snackbar('Success', 'Task deleted successfully!');
    } catch (e) {
      error.value = 'Failed to delete task: $e';
      Get.snackbar('Error', error.value);
    } finally {
      isLoading.value = false;
    }
  }
}
