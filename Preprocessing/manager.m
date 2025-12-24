% 分類ごとに病理画像データ（*.ndpi）がディレクトリに収納されており、それらディレクトリがまとめられているルートディレクトリのパス
root = fullfile("");

% 病理画像の分類名
classes = ["AIH","DILI"];

% ndpisplit.exeが入っているディレクトリのパス
ndpisplit_exe_path = root;

% 色の標準化の際に基準となるデータが収納されているディレクトリ
standard_path = fullfile("","standard");

% 切り取る際の横幅
width = 224;

% 切り取る際の縦幅
height = 224;

file_manager = NAZNdpiFilesManagement(root,classes,ndpisplit_exe_path,standard_path,width,height);

file_manager.init;

% 画像切り取り開始
file_manager.run;