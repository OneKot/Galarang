using System;
using UnityEditor;
using UnityEditor.TestTools.TestRunner.Api;
using UnityEngine;

namespace Galarang.EditorTools
{
    /// <summary>
    /// Запуск EditMode-тестов из командной строки:
    /// -executeMethod Galarang.EditorTools.CommandLineTestRunner.Run
    /// Без -quit: редактор завершается сам через EditorApplication.Exit с кодом
    /// 0 — успех, 1 — есть упавшие, 2 — тесты не найдены, 3 — таймаут.
    /// </summary>
    public static class CommandLineTestRunner
    {
        const int ExitOk = 0;
        const int ExitTestsFailed = 1;
        const int ExitNoTests = 2;
        const int ExitTimeout = 3;

        public static void Run()
        {
            var api = ScriptableObject.CreateInstance<TestRunnerApi>();
            var settings = new ExecutionSettings(new Filter { testMode = TestMode.EditMode });
            var callbacks = new Callbacks();
            api.RegisterCallbacks(callbacks);
            api.Execute(settings);

            var deadline = DateTime.UtcNow.AddMinutes(10);
            EditorApplication.update += Tick;

            void Tick()
            {
                if (callbacks.Finished)
                {
                    EditorApplication.update -= Tick;
                    var result = callbacks.Result;
                    Debug.Log($"[Galarang.Tests] passed={result.PassCount} failed={result.FailCount} skipped={result.SkipCount}");
                    EditorApplication.Exit(result.FailCount > 0 ? ExitTestsFailed
                        : result.PassCount > 0 ? ExitOk : ExitNoTests);
                }
                else if (DateTime.UtcNow > deadline)
                {
                    EditorApplication.update -= Tick;
                    Debug.LogError("[Galarang.Tests] Таймаут прогона (10 минут).");
                    EditorApplication.Exit(ExitTimeout);
                }
            }
        }

        sealed class Callbacks : ICallbacks
        {
            public bool Finished;
            public ITestResultAdaptor Result;

            public void RunStarted(ITestAdaptor testsToRun)
            {
                Debug.Log($"[Galarang.Tests] Старт: {testsToRun.TestCaseCount} кейсов.");
            }

            public void RunFinished(ITestResultAdaptor testResults)
            {
                Result = testResults;
                Finished = true;
            }

            public void TestStarted(ITestAdaptor test)
            {
            }

            public void TestFinished(ITestResultAdaptor result)
            {
                if (result.TestStatus == TestStatus.Failed)
                    Debug.LogError($"[FAIL] {result.FullName}: {result.Message}");
                else
                    Debug.Log($"[PASS] {result.FullName}");
            }
        }
    }
}
