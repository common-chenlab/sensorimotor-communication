function save_parfor2(whiskers, measurements, raw_folder, original_file)
save([raw_folder original_file '.mat'],'whiskers','-append', '-v6');
save([raw_folder original_file '.mat'],'measurements','-append', '-v6');
end