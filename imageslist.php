<?php

// Replace this path with the actual path to your image folder
$imagePath = '/gallery/images/film_fullsize';

$imageList = array();

// Read the contents of the image folder
if ($handle = opendir($imagePath)) {
    while (false !== ($file = readdir($handle))) {
        if ($file !== '.' && $file !== '..' && preg_match('/\.(jpg|jpeg|png|gif)$/i', $file)) {
            $imageList[] = $file;
        }
    }
    closedir($handle);
}

// Send the list as a JSON response
header('Content-Type: application/json');
echo json_encode(['images' => $imageList]);

?>
