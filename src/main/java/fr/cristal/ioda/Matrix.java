package fr.cristal.ioda;

import java.util.LinkedHashMap ;
import java.util.ArrayList ;
import java.util.Iterator ;
import java.util.StringTokenizer ;
import java.io.IOException ;
import java.io.BufferedReader ;
import java.io.StringReader ;

import org.nlogo.api.*;
import org.nlogo.core.ExtensionObject;
import org.nlogo.core.LogoList;
import org.nlogo.core.Syntax;
import org.nlogo.core.SyntaxJ;

/** <p>This class is part of the IODA NetLogo extension.<bR> All
 * contents &copy; 2008-2024 Sébastien PICAULT and Philippe
 * MATHIEU<br> Centre de Recherche en Informatique, Signal et
 * Automatique de Lille (CRIStAL), UMR CNRS 9189<br> Université de
 * Lille (Sciences et Technologies) – Cité Scientifique, F-59655
 * Villeneuve d'Ascq Cedex, FRANCE.<br> Web Site: <a
 * href="https://github.com/cristal-smac/ioda">https://github.com/cristal-smac/ioda</a></p>
 * <p>The IODA NetLogo extension is free software: you can
 * redistribute it and/or modify it under the terms of the GNU General
 * Public License as published by the Free Software Foundation, either
 * version 3 of the License, or (at your option) any later
 * version.</p> <p>The IODA NetLogo extension is distributed in the
 * hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 * PURPOSE. See the GNU General Public License for more details.</p>
 * <p>You should have received a copy of the GNU General Public
 * License along with the IODA NetLogo extension. If not, see <a
 * href="http://www.gnu.org/licenses">http://www.gnu.org/licenses</a>.</p>
 *
 * @author Sébastien Picault
 * @author Nathan Hallez
 * @author Philippe Mathieu
 *
 * @see <a href="https://www.cristal.univ-lille.fr/SMAC/projects/ioda/index-2.html">The IODA Webpage</a>
 * @version IODA Extension 3.0 - Jul. 2024
 */
public class Matrix implements ExtensionObject {
    private static long next = 0 ;
    static Matrix interactionMatrix = new Matrix() ;
    static Matrix updateMatrix = new Matrix() ;
    private static LinkedHashMap<AgentSet, ArrayList<AgentSet>> potentialTargets = new LinkedHashMap<AgentSet, ArrayList<AgentSet>>() ;

    private final long id ;
    private ArrayList<AgentSet> passiveBreeds ;
    private LinkedHashMap<AgentSet, ArrayList<ArrayList<Assignation>>> matrix ;


    public static void readFromString(Context context, String fileName, String fileContent, String delim) throws IOException, ExtensionException {
	boolean removal = false ;
	StringReader fileIn = new StringReader(fileContent) ;
	BufferedReader in = new BufferedReader(fileIn) ;
	String line, name = null ;
	int number = 0 ;
	StringTokenizer t ;	
	while ((line = in.readLine()) != null) {
	    number++;
	    if (line.startsWith("-")) {
		removal = true ;
		line = line.substring(1) ;
	    } else if (line.startsWith("+"))
		line = line.substring(1);
	    if ((line.length()>0) && (Character.isLetterOrDigit(line.charAt(0)))) {
		t = new StringTokenizer(line, delim) ;
		LogoListBuilder l = new LogoListBuilder();
		String source, target, inter, method = "RANDOM" ;
		AgentSet srcBreed = null, tgtBreed = null ;
		double priority = 0, distance = 0;
		int nb = t.countTokens() ;
		target = "nobody" ;
		boolean update = false ;
		if (nb < 3) 
		    throw new ExtensionException("In file: "+fileName+" line "+number+": missing columns in CSV") ;	
		source = t.nextToken().toLowerCase() ;
		srcBreed = IodaExtension.findBreedNamed(context, source) ;
		if ((!source.equals("nobody")) && (srcBreed == null))
		    throw new ExtensionException("In file: "+fileName+" line "+number+": unknow breed "+source) ;	
		inter = t.nextToken().toLowerCase() ;
		if (!Interaction.interactions.containsKey(inter))
		    throw new ExtensionException("In file: "+fileName+" line "+number+": unknow interaction "+inter) ;	
		priority = Double.parseDouble(t.nextToken());
		if (nb > 3) {
		    target = t.nextToken().toLowerCase() ;
		    if (target.equals("update")) {
			update = true ;
			target = "nobody" ;
		    }
		    else {
			tgtBreed = IodaExtension.findBreedNamed(context, target) ;
			if ((!target.equals("nobody")) && (tgtBreed == null))
			    throw new ExtensionException("In file: "+fileName+" line "+number+": unknow breed "+target) ;	
			if (nb > 4) {
			    distance = Double.parseDouble(t.nextToken());
			    if (nb > 5) {
				method = t.nextToken().toUpperCase() ;
				if (!(method.equals("RANDOM") || method.equals("RANDOM-INT") 
				      || method.startsWith("PRORATA:") || method.startsWith("FILTER:") 
				      || method.startsWith("NUMBER:")  || method.startsWith("BEST:") 
				      || method.startsWith("ALL-BEST:") || method.equals("ALL")))
				    throw new ExtensionException("In file: "+fileName+" line "+number+": unknow target selection method "+method) ;	
			    }
			}
		    }
		}
		l.add(source) ; l.add(inter) ; l.add(priority) ; l.add(target) ; l.add(distance) ;
		Assignation a = new Assignation(l.toLogoList()) ;
		a.setTargetSelectionMethod(method) ;
		if (removal) {
		    if (update)
			updateMatrix.removeAssignation(context, srcBreed, a, null) ;
		    else
			interactionMatrix.removeAssignation(context, srcBreed, a, tgtBreed) ;
		} else {
		    if (update)
			updateMatrix.addAssignation(srcBreed, a, null) ;
		    else
			interactionMatrix.addAssignation(srcBreed, a, tgtBreed) ;
		}
	    }
	    removal = false ;
	}
    }

    public static LogoList getPotentialTargets(AgentSet source) {
	LogoListBuilder result = new LogoListBuilder();
	if (isActive(source)) 
	    if (potentialTargets.containsKey(source))
		for (AgentSet target: potentialTargets.get(source))
		    result.add(target) ;
	return result.toLogoList() ;
    }

    public static boolean isActive(AgentSet sourceBreed) {
	return interactionMatrix.matrix.containsKey(sourceBreed) ;
    }

    public static boolean isPassive(AgentSet targetBreed) {
	return interactionMatrix.passiveBreeds.contains(targetBreed) ;
    }

    public static boolean isLabile(AgentSet breed) {
	return updateMatrix.matrix.containsKey(breed) ;
    }
    
    public static LogoList activeBreeds() {
	LogoListBuilder result = new LogoListBuilder() ;
	result.addAll(interactionMatrix.matrix.keySet()) ;
	return result.toLogoList() ;
    }

    public static LogoList activeBreedsWithTargets() {
	LogoListBuilder result = new LogoListBuilder() ;
	for (AgentSet source: interactionMatrix.matrix.keySet())
	    if ((potentialTargets.containsKey(source)) &&
		(!potentialTargets.get(source).isEmpty()))
		result.add(source) ;
	return result.toLogoList() ;
    }

    public static LogoList passiveBreeds() {
	LogoListBuilder result = new LogoListBuilder() ;
	result.addAll(interactionMatrix.passiveBreeds) ;
	return result.toLogoList() ;
    }

    public static LogoList labileBreeds() {
	LogoListBuilder result = new LogoListBuilder() ;
	result.addAll(updateMatrix.matrix.keySet()) ;
	return result.toLogoList() ;
    }

    public static void clearAll() { 
	next = 0 ; 
	interactionMatrix = new Matrix() ;
	updateMatrix = new Matrix() ;
	potentialTargets.clear() ;
    }


    public Matrix() {
	this.id = next ;
	next++ ;
	matrix = new LinkedHashMap<AgentSet, ArrayList<ArrayList<Assignation>>>() ;
	passiveBreeds = new ArrayList<AgentSet>() ;
    }

    public ArrayList<Assignation> collectAssignations() {
	ArrayList<Assignation> result = new ArrayList<Assignation>() ;
	for (AgentSet source: matrix.keySet()) 
	    for (ArrayList<Assignation> a: matrix.get(source))
		result.addAll(a) ;
	return result ;
    }

    public boolean equals(Object obj) { return this == obj ; }

    public LogoList toList() {
	LogoListBuilder result = new LogoListBuilder() ;
	for (AgentSet source: matrix.keySet()) 
	    for (ArrayList<Assignation> aList: matrix.get(source)) 
		for (Assignation a: aList)
		    result.add(a) ;
	return result.toLogoList() ;
    }

    public LogoList toSortedList() {
	LogoListBuilder result = new LogoListBuilder() ;
	for (AgentSet source: matrix.keySet()) 
	    result.add(this.getMatrixLine(source).fput(source)) ;
	return result.toLogoList() ;
    }

    public String dump(boolean readable, boolean exportable, boolean reference) {
	if (exportable && reference) 
	    return (""+id) ;
	else 
	    return (exportable?(id+": "):"") + org.nlogo.api.Dump.logoObject(this.toList(), true, exportable) ;
    }

    public String getExtensionName() { return "ioda" ; }
    public String getNLTypeName() { return "matrix" ; }

    public boolean recursivelyEqual(Object o) {
	if (!(o instanceof Matrix))
	    return false ;
	Matrix a = (Matrix) o ;
	return  this.toSortedList().equals(a.toSortedList()) ;
    }


    public LogoList getMatrixLine(AgentSet sourceBreed) {
	LogoListBuilder aList, bList ;
	aList = new LogoListBuilder() ;
	if (matrix.containsKey(sourceBreed)) {
	    for (ArrayList<Assignation> cList: matrix.get(sourceBreed)) {
		bList = new LogoListBuilder() ;
		for (Assignation a: cList)
		    bList.add(a) ;
	    aList.add(bList.toLogoList()) ;
	    }
	}
	return aList.toLogoList() ;
    }

    public void addAssignation(AgentSet source, Assignation a, AgentSet target) {
	if (!matrix.containsKey(source))
	    matrix.put(source, new ArrayList<ArrayList<Assignation>>()) ;
	ArrayList<ArrayList<Assignation>> line = matrix.get(source) ;
	ArrayList<Assignation> block = null ;
	int i = 0 ; 
	while ((i<line.size()) && (block == null)) {
	    double p = line.get(i).get(0).getPriority() ; 
	    if (a.getPriority() > p) 
		block = new ArrayList<Assignation>() ; 
	    else if (a.getPriority() == p)
		block = line.get(i) ;
	    else i++ ;
	}
	if (block == null) 
	    block = new ArrayList<Assignation>() ;
	if (!block.contains(a)) {
	    block.add(a) ;
	    if (target != null) {
		if (!passiveBreeds.contains(target))
		    passiveBreeds.add(target) ;
		if (!potentialTargets.containsKey(source)) 
		    potentialTargets.put(source, new ArrayList<AgentSet>()) ;
		ArrayList<AgentSet> targs = potentialTargets.get(source) ;
		if (!targs.contains(target))
		    targs.add(target) ;
	    }
	    if (block.size() == 1) 
		line.add(i, block) ;
	}
    }

    public boolean removeAssignation(Context context, AgentSet source, Assignation a, AgentSet target) {
	if (!matrix.containsKey(source))
	    return false ;
	boolean result = false ;
	ArrayList<ArrayList<Assignation>> line = matrix.get(source) ;
	Iterator<ArrayList<Assignation>> iter = line.iterator() ;
	while (iter.hasNext()) {
	    ArrayList<Assignation> block = iter.next() ;
	    double p = block.get(0).getPriority() ;
	    if (a.getPriority() > p)
		return false ;
	    if (a.getPriority() == p) {
		Iterator<Assignation> ita = block.iterator() ;
		result = false ;
		while (ita.hasNext()) {
		    if (ita.next().equals(a)) {
			ita.remove() ;
			result = true ;
		    }
		}
		if (result && (target != null)) {
		    recomputePotentialTargets(context, source, target) ;
		    recomputePassiveBreeds(context, source, target) ;
		}
		if (block.isEmpty())
		    iter.remove() ;
	    }
	}
	if (line.isEmpty())
	    matrix.remove(source);
	return result ;
    }
    
    protected boolean recomputePotentialTargets(Context context, AgentSet source, AgentSet target) {
	if (!potentialTargets.containsKey(source)) 
	    return false ;
	ArrayList<AgentSet> targs = potentialTargets.get(source) ;
	if (!targs.contains(target))
	    return false ;
	ArrayList<ArrayList<Assignation>> line = matrix.get(source) ;
	for (ArrayList<Assignation> block: line)
	    for (Assignation a: block) {
		String tgt = a.getTarget() ;
		if (!tgt.equalsIgnoreCase("nobody"))
		    if (IodaExtension.findBreedNamed(context, tgt).equals(target))
			return false ;
	    }
	return targs.remove(target) ;
    }

    protected boolean recomputePassiveBreeds(Context context, AgentSet source, AgentSet target) {
	if (!passiveBreeds.contains(target))
	    return false ;
	for (ArrayList<ArrayList<Assignation>> line: matrix.values())
	    for (ArrayList<Assignation> block: line)
		for (Assignation a: block) {
		    String tgt = a.getTarget() ;
		    if (!tgt.equalsIgnoreCase("nobody")) 
			if (IodaExtension.findBreedNamed(context, tgt).equals(target))
			    return false ;
		}
	return passiveBreeds.remove(target) ;
    }
    
    //----------------------------------------------------------------
    public static class MatrixMake implements Reporter {
	public Syntax getSyntax() {
	    return SyntaxJ.reporterSyntax(new int[] {}, Syntax.WildcardType()) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public Object report(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    return new Matrix() ;
	}
    }    

    //----------------------------------------------------------------
    public static class MatrixView implements Reporter {
	public Syntax getSyntax() {
	    return SyntaxJ.reporterSyntax(new int[] {Syntax.WildcardType()}, Syntax.ListType()) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public Object report(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    Object arg0 = args[0].get() ;
	    if (!(arg0 instanceof Matrix))
		throw new ExtensionException("not a matrix: "+org.nlogo.api.Dump.logoObject(arg0)) ;
	    Matrix m = (Matrix) arg0 ;
	    return m.toSortedList() ;
	}
    }    

    //----------------------------------------------------------------
    public static class GetMatrixLine implements Reporter {
	public Syntax getSyntax() {
	    return SyntaxJ.reporterSyntax(new int[] {Syntax.WildcardType(), Syntax.AgentsetType()}, Syntax.ListType()) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public Object report(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    Object arg0 = args[0].get() ;
	    if (!(arg0 instanceof Matrix))
		throw new ExtensionException("not a matrix: "+org.nlogo.api.Dump.logoObject(arg0)) ;
	    Matrix m = (Matrix) arg0 ;
	    return m.getMatrixLine(args[1].getAgentSet()) ;
	}
    }    

    //----------------------------------------------------------------
    public static class GetBreedTargets implements Reporter {
	public Syntax getSyntax() {
	    return SyntaxJ.reporterSyntax(new int[] {Syntax.AgentsetType()}, Syntax.ListType()) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public Object report(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    AgentSet source = args[0].getAgentSet() ;
	    return getPotentialTargets(source) ;
	}
    }    

    //----------------------------------------------------------------
    public static class IsActive implements Reporter {
	public Syntax getSyntax() {
	    return SyntaxJ.reporterSyntax(new int[] {}, Syntax.BooleanType()) ;
	}
	public String getAgentClassString() { return "TP" ; }
	public Object report(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    return isActive(IodaExtension.findBreedOfCaller(context)) ;
	}
    }    

    //----------------------------------------------------------------
    public static class IsPassive implements Reporter {
	public Syntax getSyntax() {
	    return SyntaxJ.reporterSyntax(new int[] {}, Syntax.BooleanType()) ;
	}
	public String getAgentClassString() { return "TP" ; }
	public Object report(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    return isPassive(IodaExtension.findBreedOfCaller(context)) ;
	}
    }    

    //----------------------------------------------------------------
    public static class IsLabile implements Reporter {
	public Syntax getSyntax() {
	    return SyntaxJ.reporterSyntax(new int[] {}, Syntax.BooleanType()) ;
	}
	public String getAgentClassString() { return "TP" ; }
	public Object report(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    return isLabile(IodaExtension.findBreedOfCaller(context)) ;
	}
    }    

    //----------------------------------------------------------------
    public static class ActiveAgents implements Reporter {
	public Syntax getSyntax() {
	    return SyntaxJ.reporterSyntax(new int[] {}, Syntax.ListType()) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public Object report(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    return activeBreeds() ;
	}
    }    

    //----------------------------------------------------------------
    public static class ActiveAgentsWithTargets implements Reporter {
	public Syntax getSyntax() {
	    return SyntaxJ.reporterSyntax(new int[] {}, Syntax.ListType()) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public Object report(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    return activeBreedsWithTargets() ;
	}
    }    

    //----------------------------------------------------------------
    public static class PassiveAgents implements Reporter {
	public Syntax getSyntax() {
	    return SyntaxJ.reporterSyntax(new int[] {}, Syntax.ListType()) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public Object report(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    return passiveBreeds() ;
	}
    }    

    //----------------------------------------------------------------
    public static class LabileAgents implements Reporter {
	public Syntax getSyntax() {
	    return SyntaxJ.reporterSyntax(new int[] {}, Syntax.ListType()) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public Object report(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    return labileBreeds() ;
	}
    }    


    //----------------------------------------------------------------
    public static class GetInteractionMatrix implements Reporter {
	public Syntax getSyntax() {
	    return SyntaxJ.reporterSyntax(new int[] {}, Syntax.WildcardType()) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public Object report(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    return interactionMatrix ;
	}
    }    

    //----------------------------------------------------------------
    public static class SetInteractionMatrix implements Command {
	public Syntax getSyntax() {
	    return SyntaxJ.commandSyntax(new int[] {Syntax.WildcardType()}) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public void perform(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    Object arg0 = args[0].get() ;
	    if (!(arg0 instanceof Matrix))
		throw new ExtensionException("not a matrix: "+org.nlogo.api.Dump.logoObject(arg0)) ;
	    interactionMatrix = (Matrix) arg0 ;
	}
    }    

    //----------------------------------------------------------------
    public static class GetUpdateMatrix implements Reporter {
	public Syntax getSyntax() {
	    return SyntaxJ.reporterSyntax(new int[] {}, Syntax.WildcardType()) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public Object report(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    return updateMatrix ;
	}
    }    

    //----------------------------------------------------------------
    public static class SetUpdateMatrix implements Command {
	public Syntax getSyntax() {
	    return SyntaxJ.commandSyntax(new int[] {Syntax.WildcardType()}) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public void perform(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    Object arg0 = args[0].get() ;
	    if (!(arg0 instanceof Matrix))
		throw new ExtensionException("not a matrix: "+org.nlogo.api.Dump.logoObject(arg0)) ;
	    updateMatrix = (Matrix) arg0 ;
	}
    }    

    

    //----------------------------------------------------------------
    public static class AddAssignation implements Command {
	public Syntax getSyntax() {
	    return SyntaxJ.commandSyntax(new int[] {Syntax.WildcardType(), Syntax.WildcardType()}) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public void perform(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    Object arg0 = args[0].get() ;
	    if (!(arg0 instanceof Matrix))
		throw new ExtensionException("not a matrix: "+org.nlogo.api.Dump.logoObject(arg0)) ;
	    Object arg1 = args[1].get() ;
	    if (!(arg1 instanceof Assignation))
		throw new ExtensionException("not an assignation: "+org.nlogo.api.Dump.logoObject(arg1)) ;
	    Matrix m = (Matrix) arg0 ;
	    Assignation a = (Assignation) arg1 ;
	    String srcBreed = a.getSource() ;
	    AgentSet source, target ;
	    source = IodaExtension.findBreedNamed(context, srcBreed) ;
	    String tgtBreed = a.getTarget() ;
	    if (tgtBreed.equalsIgnoreCase("nobody"))
		target = null ;
	    else target = IodaExtension.findBreedNamed(context, tgtBreed) ;
	    m.addAssignation(source, a, target) ;
	}
    }    

    //----------------------------------------------------------------
    public static class RemoveAssignation implements Command {
	public Syntax getSyntax() {
	    return SyntaxJ.commandSyntax(new int[] {Syntax.WildcardType(), Syntax.WildcardType()}) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public void perform(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    Object arg0 = args[0].get() ;
	    if (!(arg0 instanceof Matrix))
		throw new ExtensionException("not a matrix: "+org.nlogo.api.Dump.logoObject(arg0)) ;
	    Object arg1 = args[1].get() ;
	    if (!(arg1 instanceof Assignation))
		throw new ExtensionException("not an assignation: "+org.nlogo.api.Dump.logoObject(arg1)) ;
	    Matrix m = (Matrix) arg0 ;
	    Assignation a = (Assignation) arg1 ;
	    String srcBreed = a.getSource() ;
	    AgentSet source, target ;
	    source = IodaExtension.findBreedNamed(context, srcBreed) ;
	    String tgtBreed = a.getTarget() ;
	    if (tgtBreed.equalsIgnoreCase("nobody"))
		target = null ;
	    else target = IodaExtension.findBreedNamed(context, tgtBreed) ;
	    m.removeAssignation(context, source, a, target) ;
	}
    }    

    //----------------------------------------------------------------
    public static class LoadMatrices  implements Command {
	public Syntax getSyntax() {
	    return SyntaxJ.commandSyntax(new int[] {Syntax.StringType(), Syntax.StringType(), Syntax.StringType()}) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public void perform(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    try { readFromString(context, args[0].getString(), args[1].getString(), args[2].getString()) ; }
	    catch(IOException e) {
		throw new ExtensionException(e.getMessage()) ;
	    } 
	}
    }

    //----------------------------------------------------------------
    public static class ClearMatrices  implements Command {
	public Syntax getSyntax() {
	    return SyntaxJ.commandSyntax(new int[] {}) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public void perform(Argument args[], Context context) {
	    clearAll() ;
	}
    }

    //----------------------------------------------------------------
    public static class MatrixToList implements Reporter {
	public Syntax getSyntax() {
	    return SyntaxJ.reporterSyntax(new int[] {Syntax.WildcardType()}, Syntax.ListType()) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public Object report(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    Object arg0 = args[0].get() ;
	    if (!(arg0 instanceof Matrix))
		throw new ExtensionException("not a matrix: "+org.nlogo.api.Dump.logoObject(arg0)) ;
	    Matrix m = (Matrix) arg0 ;
	    LogoListBuilder l = new LogoListBuilder() ;
	    l.addAll(m.collectAssignations()) ;
	    return l.toLogoList() ;
	}
    }    

    //----------------------------------------------------------------
    public static class PrintInteractionMatrix implements Reporter {
	public Syntax getSyntax() {
	    return SyntaxJ.reporterSyntax(new int[] {}, Syntax.StringType()) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public Object report(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    StringBuffer b = new StringBuffer() ;
	    for (Assignation a: interactionMatrix.collectAssignations())
		b.append(a.toString() + "\n") ;
	    return b.toString() ;
	}
    }

    //----------------------------------------------------------------
    public static class PrintUpdateMatrix implements Reporter {
	public Syntax getSyntax() {
	    return SyntaxJ.reporterSyntax(new int[] {}, Syntax.StringType()) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public Object report(Argument args[], Context context) 
	    throws ExtensionException, LogoException {
	    StringBuffer b = new StringBuffer() ;
	    for (Assignation a: updateMatrix.collectAssignations())
		b.append(a.toString() + "\tUPDATE\n") ;
	    return b.toString() ;
	}
    }
}
