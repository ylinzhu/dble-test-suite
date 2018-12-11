﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace netdriver
{
    class GetFile
    {
        public static List<String> GetFiles(String[] filepath)
        {
            //文件存在
            List<String> files = new List<String>();
            for (int i = 0; i < filepath.Length; i++)
            {
                var file = filepath[i];
                Console.WriteLine(filepath[i]);
                if (!File.Exists(file))
                {
                    Console.WriteLine(filepath[i] + "  doesn't exists");
                }
                else
                {
                    files.Add(filepath[i]);
                }
            }
            return files;
        }
    }
}