const express = require('express')
const path = require('path')
const bodyparser = require('body-parser')
const multer = require('multer')
const {uploadCsv} = require('@shamigondal/csv-uploader')
const connectToDatabase = require('./db');



const app = express();

app.use(bodyparser.urlencoded({ extended: false }))
app.use(bodyparser.json())

const PORT = 4000 || 3000;
const localhost = `http://localhost:`

const storage = multer.diskStorage({

    destination: (req, file, callback) => {
        callback(null, './uploads')
    },
    filename: (req, file, callback) => {
        callback(null, file.fieldname + '-' + Date.now() + path.extname(file.originalname))
    }
})

const uploads = multer({
    storage: storage
})


app.get('/', (req, res) => {

    res.sendFile(__dirname + '/index.html')
})


app.post('/post-Csv-file', uploads.single('file'), async (req, res) => {
  try {
      console.log(req.file.path);
      const tableName = '[user]'; // Replace with your table name
      const columnNames = ['userID', 'FirstName', 'LastName', 'Email','Password','UserType']; // Replace with your column names
      await uploadCsv(path.join(__dirname, 'uploads', req.file.filename), tableName, columnNames, connectToDatabase);
      res.sendFile(__dirname + '/success.html');
  } catch (error) {
      console.error('Error processing CSV file:', error);
      res.status(500).send('Internal Server Error');
  }
});

app.get('/courses', (req, res) => {

    res.sendFile(__dirname + '/courses.html')
})

app.get('/Report', (req, res) => {

    res.sendFile(__dirname + '/bulk.html')
})

app.post('/post-Csv-file/courses', uploads.single('file'), async (req, res) => {
  try {
      console.log(req.file.path);
      const tableName = 'Course'; // Replace with your table name
      const columnNames = ['CourseID', 'CourseName', 'CourseDescription', 'TeacherID','AdminID']; // Replace with your column names
      await uploadCsv(path.join(__dirname, 'uploads', req.file.filename), tableName, columnNames, connectToDatabase);
      res.sendFile(__dirname + '/success.html');
  } catch (error) {
      console.error('Error processing CSV file:', error);
      res.status(500).send('Internal Server Error');
  }
});

app.post('/post-Csv-file/Report', uploads.single('file'), async (req, res) => {
    try {
        console.log(req.file.path);
        const tableName = 'Report'; // Replace with your table name
        const columnNames = [
            "StudentUserID",
            "StudentFirstName",
            "StudentLastName",
            "CourseID",
            "CourseName",
            "CourseDescription",
            "EnrollmentID",
            "EnrollmentDate",
            "ExamID",
            "ExamTitle",
            "TotalMarks",
            "ObtainedMarks",
            "ExamDate",
            "ExamType"
        ]; // Replace with your column names
        await uploadCsv(path.join(__dirname, 'uploads', req.file.filename), tableName, columnNames, connectToDatabase);
        res.sendFile(__dirname + '/success.html');
    } catch (error) {
        console.error('Error processing CSV file:', error);
        res.status(500).send('Internal Server Error');
    }
  });
  
  

app.listen(PORT, (req, res) => {

    console.log("CSV Faker listening at PORT " + localhost + PORT)
})