#
תשובות -
1. המחלקה המממשת את ה-controller עבור ה-snappingSheet היא ה- snappingSheetController.
ה-controller מאפשר לשלוט במיקום ה-snappingSheet, כלומר ניתן לשנות את מיקום ה-snappingSheet. בנוסף, ניתן לקבל את המיקום הנוכחי של ה-snappingSheet.


2. הפרמטר ששולט באנימציה של ה-snappingSheet, הוא snappingCurve.


3. יתרון של InkWell: מאפשר אפקט לחיצה מתפשט על הContainer לעומת ה-GestureDetector.

יתרון של GestureDetector: מאפשר לחיצות שונות (כמו לחיצה פעמיים, לחיצה ארוכה) לעומת ה-InkWell שמאפשר רק לחיצה.
